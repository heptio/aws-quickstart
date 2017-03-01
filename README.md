![AWS Quick Start for Kubernets](images/banner.jpg)

# Heptio AWS Quickstart

These are the CloudFormation templates and Packer configs for the Heptio AWS Quick Start.  This is where active development is happening.

Details of the Quick Start are in this [Heptio Blog post](https://blog.heptio.com/aws-quickstart-for-kubernetes-26ccaf7e1c8f#.aqb0bit5l)

Amazon's page for this is [here](https://aws.amazon.com/quickstart/architecture/heptio-kubernetes/).

This will be updated and pushed regularly to https://github.com/aws-quickstart/quickstart-heptio.

## Deploying

More complete instructions coming soon.

```
STACK=stack-name
TEMPLATEPATH=file://templates/kubernetes-cluster-with-new-vpc.template
KEYNAME=<aws-key-name>
AZ=us-west-2b
aws cloudformation create-stack \
  --stack-name $STACK \
  --template-body $TEMPLATEPATH \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
  --capabilities=CAPABILITY_IAM
```

The files in this repo are mirrored to S3 for testing purposes.  If you want to develop/test updates do the following:
```
HEPTIO_S3_BUCKET=heptio-aws-quickstart-test
HEPTIO_S3_KEY_PREFIX=heptio/kubernetes/latest
aws s3 sync \
  --exclude .git \
  --exclude .git/\* \
  --exclude .vscode \
  --exclude '.vscode/*' \
  --exclude .gitmodules \
  --acl=public-read \
  ./ s3://${HEPTIO_S3_BUCKET}/${HEPTIO_S3_KEY_PREFIX}/
```

If you are using a different bucket/prefix, you need to tell the CFn create-stack about it.
```
aws cloudformation create-stack \
  --stack-name $STACK \
  --template-body $TEMPLATEPATH \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=QSS3BucketName,ParameterValue=$HEPTIO_S3_BUCKET \
    ParameterKey=QSS3KeyPrefix,ParameterValue=$HEPTIO_S3_KEY_PREFIX \
  --capabilities=CAPABILITY_IAM
```
## Using the cluster

```
# Wait for the cluster to be up and running
aws cloudformation wait stack-create-complete --stack-name $STACK

# Get the command to download the kubeconfig file for the cluster
KUBECFG_DL=$(aws cloudformation describe-stacks --stack-name=$STACK --query 'Stacks[0].Outputs[?OutputKey==`GetKubeConfigCommand`].OutputValue' --output text)
echo $KUBECFG_DL
eval $KUBECFG_DL

# Set an environment variable to tell kubectl where to find this file
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```
