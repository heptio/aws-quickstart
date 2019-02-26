#!/usr/bin/env bash

# This is where VMware stores templates/scripts for the master branch of this repository
S3_BUCKET=vmware-aws-quickstart-test
S3_PREFIX=vmware/kubernetes/master/

# Where to place your cluster
REGION=us-west-2
AZ=us-west-2b

# What to name your CloudFormation stack
STACK=VMware-Kubernetes

# What SSH key you want to allow access to the cluster (must be created ahead of time in your AWS EC2 account)
KEYNAME=mykey

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

aws cloudformation create-stack \
  --region $REGION \
  --stack-name $STACK \
  --template-url "https://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS \
    ParameterKey=QSS3BucketName,ParameterValue=${S3_BUCKET} \
    ParameterKey=QSS3KeyPrefix,ParameterValue=${S3_PREFIX} \
  --capabilities=CAPABILITY_IAM
