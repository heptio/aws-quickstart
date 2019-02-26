#!/bin/bash

# Copyright 2017 by the contributors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# This runs integration tests for the local repository, deploying it to
# CloudFormation and testing various bits of functionality underneath.

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

export ERRCODE_FAILURE=1
export ERRCODE_TIMEOUT=10

if [[ "$(whoami)" != "root" ]] || ! grep -q Alpine /etc/issue 2>/dev/null; then
    echo "This script must be run in a docker container (and will make changes to the filesystem). Exiting."
    exit 1
fi

# Sanity check (this script should be launched by all-docker.sh or similar)
test -n "${AWS_ACCESS_KEY_ID}"
test -n "${AWS_SECRET_ACCESS_KEY}"
test -n "${AZ}"
test -n "${REGION}"
test -n "${S3_BUCKET}"
test -n "${S3_PREFIX}"
test -n "${STACK_NAME}"

export AWS_DEFAULT_REGION="${REGION}"
export SSH_KEY_NAME="${STACK_NAME}-key"

# Setup ssh.  Due to SSH being incredibly paranoid about filesystem permissions
# we just create our own ssh directory and set it from there.  (This also
# allows the docker volume mounts to be read-only.)
out=$(aws ec2  create-key-pair  --region "${REGION}" --key-name "${SSH_KEY_NAME}")
test ! -e /tmp/qs-ssh/identity
mkdir -p /tmp/qs-ssh
chmod 0700 /tmp/qs-ssh
echo -n $out| jq -r '.KeyMaterial' > /tmp/qs-ssh/identity
export SSH_KEY=/tmp/qs-ssh/identity
chmod 0600 $SSH_KEY

aws --version >/dev/null
kubectl version --client >/dev/null
sonobuoy version >/dev/null

aws s3 sync --acl=public-read --delete ./templates "s3://${S3_BUCKET}/${S3_PREFIX}templates/"
aws s3 sync --acl=public-read --delete ./scripts "s3://${S3_BUCKET}/${S3_PREFIX}scripts/"

# TODO: maybe do a calico test and a weave test as separate runs
aws cloudformation create-stack \
  --disable-rollback \
  --region "${REGION}" \
  --stack-name "${STACK_NAME}" \
  --template-url "https://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
  ParameterKey=AvailabilityZone,ParameterValue="${AZ}" \
  ParameterKey=KeyName,ParameterValue="${SSH_KEY_NAME}" \
  ParameterKey=QSS3BucketName,ParameterValue="${S3_BUCKET}" \
  ParameterKey=QSS3KeyPrefix,ParameterValue="${S3_PREFIX}" \
  ParameterKey=AdminIngressLocation,ParameterValue=0.0.0.0/0 \
  ParameterKey=NetworkingProvider,ParameterValue=calico \
  --capabilities=CAPABILITY_IAM

aws cloudformation wait stack-create-complete --stack-name "${STACK_NAME}"

function cleanup() {
    trap - EXIT
    echo "Deleting test files from s3"
    aws s3 rm --recursive "s3://${S3_BUCKET}/${S3_PREFIX}"
    echo "Deleting cloudformation stack ${STACK_NAME}"
    aws cloudformation delete-stack --stack-name "${STACK_NAME}"
    aws cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}"
    aws ec2 delete-key-pair --key-name "${SSH_KEY_NAME}" --region "${REGION}"
}
trap cleanup EXIT

# Pre-load the SSH host keys
BASTION_IP=$(aws cloudformation describe-stacks \
    --query 'Stacks[*].Outputs[?OutputKey == `BastionHostPublicIp`].OutputValue' \
    --output text --stack-name $STACK_NAME
)
MASTER_IP=$(aws cloudformation describe-stacks \
    --query 'Stacks[*].Outputs[?OutputKey == `MasterPrivateIp`].OutputValue' \
    --output text --stack-name $STACK_NAME
)
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ubuntu@${BASTION_IP} nc %h %p" ubuntu@${MASTER_IP} exit 0

# TODO: this is a hack... GetKubeConfigCommand has a fake
# "SSH_KEY=path/to/blah.pem" output, we want to override that with our actual
# one.
KUBECONFIG_COMMAND=$(aws cloudformation describe-stacks \
    --query 'Stacks[*].Outputs[?OutputKey == `GetKubeConfigCommand`].OutputValue' \
    --output text --stack-name $STACK_NAME \
    | sed "s!path/to/${SSH_KEY_NAME}.pem!${SSH_KEY}!"
)

# Other than that, just run the command as the Output suggests
(
    cd /tmp
    eval "${KUBECONFIG_COMMAND}"
)

# It should have copied a "kubeconfig" file to our current directory (which was /tmp)
export KUBECONFIG=/tmp/kubeconfig

########################
# K8S tests start here #
########################

# Use heptio-sonobuoy as default namespace
kubectl config set-context heptio-sonobuoy --cluster kubernetes --user admin --namespace heptio-sonobuoy
kubectl config use-context heptio-sonobuoy

# sonobuoy provided by the Dockerfile
sonobuoy run --mode=quick

echo "Waiting for sonobuoy to complete"
tries=0
while :; do
  # TODO: sonobuoy should probably have a readiness probe
  kubectl logs sonobuoy 2>&1 | grep -q "sonobuoy is now blocking" && break
  echo -n "."
  sleep 10

  tries=$((tries+1))
  if [[ $tries -gt 30 ]]; then # 5 minutes-ish
    echo "Sonobuoy did not finish after 5 minutes.  Master logs:"
    kubectl logs sonobuoy
    echo "Sonobuoy status and logs:"
    sonobuoy status
    sonobuoy logs
    exit $ERRCODE_TIMEOUT
  fi
done

# Copy results
kubectl cp heptio-sonobuoy/sonobuoy:/tmp/sonobuoy /tmp/results

(
  cd /tmp/results
  tar -xzf *.tar.gz
  if [[ -e ./plugins/e2e/errors.json ]]; then
    echo "Sonobuoy e2e plugin returned an error.  errors.json:"
    jq . <./plugins/e2e/errors.json
    exit $ERRCODE_FAILURE
  fi

  if tail -1 ./plugins/e2e/results/e2e.log | grep -q 'Test Suite Passed'; then
    echo "Sonobuoy e2e plugin run successfully."
  else
    echo "Sonobuoy e2e plugin was not successful. Log:"
    cat ./plugins/e2e/results/e2e.log
    exit $ERRCODE_FAILURE
  fi
)
