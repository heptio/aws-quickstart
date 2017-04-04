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

# This script is for after you've run create-ami.sh and want to make the AMI
# public, and copy it to all AWS regions.

set -o errexit
set -o pipefail

log_cat() {
  if [[ "${VERBOSE}" == "true" ]]; then
    cat 1>&2
  fi
}

log() {
  if [[ "${VERBOSE}" == "true" ]]; then
    echo $* 1>&2
  fi
}

usage() {
  log "Usage: $0 -r SOURCE_REGION -i SOURCE_AMI [-q]"
  log_cat 1>&2 <<EOF

Will copy SOURCE_AMI from SOURCE_REGION to all other regions, and will mark the
image as public in all regions.  This is intended to be run with the AMI that
packer produces, with the region specified in create-ami.sh

Options:
	-q: don't output status messages, just the resulting YAML.
EOF
}

VERBOSE="true"
while getopts "r:i:q:" opt; do
  case $opt in
    r)
      SOURCE_REGION=$OPTARG
      ;;
    i)
      SOURCE_AMI=$OPTARG
      ;;
    q)
      VERBOSE=''
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${SOURCE_REGION}" || -z "${SOURCE_AMI}" ]]; then
  usage
  exit 1
fi

DEST_REGIONS=$(aws ec2 describe-regions --output json | jq -r '.Regions[].RegionName' | grep -v "^${SOURCE_REGION}$")
AMI_NAME=$(aws ec2 --region "${SOURCE_REGION}" describe-images --image-id "${SOURCE_AMI}" | jq -r '.Images[0].Name')
test -n "${AMI_NAME}"

# Copy the source AMI into each region, keeping track of what the new ID's are
REGION_AMIS=("${SOURCE_REGION},${SOURCE_AMI}")
for RGN in $DEST_REGIONS; do
  log -n "Copying to ${RGN}..."
  NEW_AMI=$(
    aws ec2 copy-image \
      --source-image-id "${SOURCE_AMI}" \
      --source-region "${SOURCE_REGION}" \
      --region "${RGN}" \
      --name "${AMI_NAME}" \
      | jq -r '.ImageId'
  )
  log $NEW_AMI

  REGION_AMIS+=("${RGN},${NEW_AMI}")
done

# We do the marking public after we've copied, because it takes a few minutes
# for them to be available, and this lets AWS do that while we copy the rest.
log
log_cat 1>&2 <<EOF
Marking images as public.  This may take a while!  While you wait, you can
paste the following into the templates/kubernetes-cluster.template RegionMap to
use the new AMIs when they're ready:
EOF
log

echo "  RegionMap:"
for STR in "${REGION_AMIS[@]}"; do
  ARR=(${STR//,/ })
  
  
  cat <<EOF
    ${ARR[0]}:
      '64': ${ARR[1]}
EOF
done
log

for STR in "${REGION_AMIS[@]}"; do
  ARR=(${STR//,/ })

  status_cmd="aws ec2 --region ${ARR[0]} describe-images --image-id ${ARR[1]} | jq -r '.Images[0].State'"

  log -n "Marking ${ARR[1]} in ${ARR[0]} as public..."

  if [[ "$(eval "${status_cmd}")" != "available" ]]; then
    log -n " waiting for it to be available"

    while [[ "$(eval "${status_cmd}")" != "available" ]]; do
      log -n "."
      sleep 5
    done
  fi

  aws ec2 --region "${ARR[0]}" modify-image-attribute --image-id "${ARR[1]}" --launch-permission '{"Add":[{"Group":"all"}]}'
  log "done"
done
