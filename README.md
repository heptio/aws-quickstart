# Heptio AWS Quickstart

Work-in-progress AWS quickstart for kubernetes

## Deploying

More complete instructions coming soon.

```
STACK=stack-name
TEMPLATEPATH=file:///....
CLUSTERTOKEN=$(python -c 'import random; print "%06x.%016x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))')
KEYNAME=<aws-key-name>
AZ=us-west-2b
aws cloudformation create-stack \
  --stack-name $STACK \
  --template-body $TEMPLATEPATH \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=ClusterToken,ParameterValue=$CLUSTERTOKEN \
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
  ./ s3://${HEPTIO_S3_BUCKET)/${HEPTIO_S3_KEY_PREFIX}/
```

If you are using a different bucket/prefix, you need to tell the CFn create-stack about it.
```
aws cloudformation create-stack \
  --stack-name $STACK \
  --template-body $TEMPLATEPATH \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=ClusterToken,ParameterValue=$CLUSTERTOKEN \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=QSS3BucketName,ParameterValue=$HEPTIO_S3_BUCKET \
    ParameterKey=QSS3KeyPrefix,ParameterValue=$HEPTIO_S3_KEY_PREFIX \
  --capabilities=CAPABILITY_IAM
```
