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

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

# Mandatory parameters
test -n "${AWS_ACCESS_KEY_ID}"
test -n "${AWS_SECRET_ACCESS_KEY}"

# Defaultable parameters
STACK_NAME="${STACK_NAME:-}"
if [[ -z "${STACK_NAME}" ]]; then
    STACK_NAME="qs-ci-$(git rev-parse --short HEAD)"
fi
AZ="${AZ:-us-west-2c}"
REGION="${REGION:-us-west-2}"
S3_BUCKET="${S3_BUCKET:-"vmware-ci-aws-quickstart"}"
S3_PREFIX="${S3_PREFIX:-${STACK_NAME}/}"

# Build the docker image
IMAGE_NAME="aws-quickstart-ci-${STACK_NAME}"
docker build -f ./ci/Dockerfile -t "${IMAGE_NAME}" .

# defer cleanup
function cleanup() {
  docker rmi -f "${IMAGE_NAME}"
}
trap cleanup EXIT

# Run e2e tests
docker run --rm \
    -e STACK_NAME="${STACK_NAME}" \
    -e REGION="${REGION}" \
    -e AZ="${AZ}" \
    -e S3_BUCKET="${S3_BUCKET}" \
    -e S3_PREFIX="${S3_PREFIX}" \
    -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
    -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
    -v "$(pwd)":/src \
    "${IMAGE_NAME}" \
    ./ci/all.sh
