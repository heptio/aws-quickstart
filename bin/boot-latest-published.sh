#!/usr/bin/env bash

# Where to place your cluster
REGION=us-west-2
AZ=us-west-2b

# What to name your CloudFormation stack
STACK=VMware-Kubernetes

# Which SSH key you want to allow access to the cluster
KEYNAME=laptop

# Import an SSH public key (or skip this command and create/import an SSH key pair in the AWS console)
aws ec2 --region $REGION import-key-pair --key-name $KEYNAME --public-key-material "$(cat ~/.ssh/id_rsa.pub)"

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

aws cloudformation create-stack \
  --region $REGION \
  --stack-name $STACK \
  --template-url "https://s3.amazonaws.com/quickstart-reference/vmware/latest/templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS \
  --capabilities=CAPABILITY_IAM
