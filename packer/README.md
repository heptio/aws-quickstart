# Building the AMI for Heptio's AWS Quick Start

This directory contains the builder scripts for the AWS AMI used by Heptio's AWS Quick Start.

Heptio's AMI is in turn built on Ubuntu 16.04 LTS.

You can see what is being done in this AMI by looking at `prepare-ami.sh`, which installs kubernetes from apt.kubernetes.io, sets up docker, the AWS CLI, and CloudFormation bootstrap tools, among other things.

## Requirements

For building the AMI, you'll need:

- [Packer](https://www.packer.io/docs/installation.html)
- An AWS Account and working AWS CLI

## Building the AMI

Just launch from the root of this repository:

```
./packer/create-ami.sh
```

## Deployment

`create-ami.sh` will publish the AMI to AWS in us-west-2 by default.  You can copy to other regions with:

```
# Copy AMI to new region
aws ec2 copy-image --source-region us-west-2 --region $REGION --source-image-id $NEW_AMI_ID --name $NEW_AMI_NAME

# Get the ID of the new AMI in the new region, and make that AMI public...
aws ec2 --region $REGION modify-image-attribute --image-id $NEW_AMI_IN_NEW_REGION_ID --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"
```
