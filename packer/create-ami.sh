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

# Based on the packer scripts used by Weaveworks:
# https://github.com/weaveworks/kubernetes-ami

set -eu

# The base AMI we build from is ubuntu Xenial in us-west-1 (see:
# https://cloud-images.ubuntu.com/locator/).  This can be revved occasionally,
# since ubuntu releases updated AMI's regularly, but it's not strictly
# necessary because running `apt-get upgrade` in our packer script accomplishes
# the same thing.
AWS_BUILDS=('us-west-1,ami-44613824')

ORIG_DIR=`pwd`
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
cd $SCRIPT_DIR

# ------------------------------------------------------------

# check 'packer' is present
if [ ! `command -v packer` ]; then
  echo "'packer' is required but not found!"
  exit 1
fi

# ------------------------------------------------------------
# util functions
invoke_packer() {

  REGION="$1"
  BASE_AMI="$2"

  PACKER_VARS="-var ami_groups=${AMI_GROUPS:-all} -var aws_region=${REGION} -var aws_base_ami=${BASE_AMI}"

  echo "PACKER_VARS: $PACKER_VARS"

  packer validate $PACKER_VARS packer-template.json && \
  echo "Validated OK" && \
  packer build -force $PACKER_VARS packer-template.json 2>&1 &

}
# ------------------------------------------------------------
# execute packer for each region & base AMI
AMI_GROUPS="${AMI_GROUPS:-all}"

for BUILD in $AWS_BUILDS; do

  array=(${BUILD//,/ })

  AWS_REGION="${array[0]}"
  AWS_BASE_AMI="${array[1]}"

  invoke_packer $AWS_REGION $AWS_BASE_AMI

done

# ------------------------------------------------------------
# wait for all to finish

echo "Waiting for builds to finish..."

wait

echo "Done."

cd $ORIG_DIR
