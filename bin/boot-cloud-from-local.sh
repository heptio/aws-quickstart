#!/usr/bin/env bash

set -o xtrace
set -o errexit
set -o nounset


# TODO(chuckha) if the bucket doesn't exist, create it. Also probably delete it at the end?

# The bucket must exist.
# Can create a bucket with something like:
# aws s3api create-bucket --bucket heptio-hello-world-idjfuiewhj --create-bucket-configuration LocationConstraint=us-west-2
S3_BUCKET="${S3_BUCKET:-quickstart-heptio-com}"

# Will error if the bucket doesn't exist or you don't have permission to it.
aws s3api head-bucket --bucket "${S3_BUCKET}"

# Where "path/to/your/files" is the directory in S3 under which the templates and scripts directories will be placed
S3_PREFIX="${S3_PREFIX:-test-local/}"

# Where to place your cluster
REGION="${REGION:-us-west-2}"
AVAILABILITY_ZONE="${AVAILABILITY_ZONE:-us-west-2a}"

# Which CNI provider you want weave/calico
CNI="${CNI:-calico}"

# What you want to call your CloudFormation stack
STACK="${STACK:-my-k8s-cluster}"

# What SSH key you want to allow access to the cluster (must be created ahead of time in your AWS EC2 account)
KEYNAME="${KEYNAME:-laptop}"

INSTANCE_TYPE="${INSTANCE_TYPE:-m5.large}"

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

# Copy the files from your local directory into your S3 bucket
aws s3 sync --acl=public-read ./templates "s3://${S3_BUCKET}/${S3_PREFIX}templates/"
aws s3 sync --acl=public-read ./scripts "s3://${S3_BUCKET}/${S3_PREFIX}scripts/"

aws cloudformation create-stack \
  --region "${REGION}" \
  --stack-name "${STACK}" \
  --template-url "https://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue="${AVAILABILITY_ZONE}" \
    ParameterKey=KeyName,ParameterValue="${KEYNAME}" \
    ParameterKey=QSS3BucketName,ParameterValue="${S3_BUCKET}" \
    ParameterKey=QSS3KeyPrefix,ParameterValue="${S3_PREFIX}" \
    ParameterKey=AdminIngressLocation,ParameterValue="${INGRESS}" \
    ParameterKey=NetworkingProvider,ParameterValue="${CNI}" \
    ParameterKey=InstanceType,ParameterValue="${INSTANCE_TYPE}" \
  --capabilities=CAPABILITY_IAM \
  --disable-rollback
