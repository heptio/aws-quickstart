# Heptio AWS Quickstart

Work-in-progress AWS quickstart for kubernetes

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
