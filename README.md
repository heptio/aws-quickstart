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