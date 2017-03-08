# Build the AMI for Heptio's AWS Quick Start

This directory contains the builder scripts for the AWS AMI that's used by Heptio's AWS Quick Start.

Heptio's AMI is in turn built on Ubuntu 16.04 LTS.

## Overview

Look at `prepare-ami.sh` to see what the AMI does:

- Installs Kubernetes from apt.kubernetes.io
- Sets up Docker, the AWS CLI, and the CloudFormation bootstrap tools
- Takes care of other requirements

## Prerequisites

To build the AMI, you need:

- [Packer](https://www.packer.io/docs/installation.html)
- An AWS account
- The AWS CLI installed and configured

## Build the AMI

From the root of this repository, run:

```
./packer/create-ami.sh
```

## Deployment

`create-ami.sh` publishes the AMI to AWS in us-west-2 by default.  You can copy to other regions with:

```
# Copy AMI to new region
aws ec2 copy-image --source-region us-west-2 --region $REGION --source-image-id $NEW_AMI_ID --name $NEW_AMI_NAME

# Get the ID of the new AMI in the new region, and make that AMI public...
aws ec2 --region $REGION modify-image-attribute --image-id $NEW_AMI_IN_NEW_REGION_ID --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"
```
