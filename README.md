![AWS Quick Start for Kubernets](images/banner.jpg)

# Heptio AWS Quickstart

These are the CloudFormation templates for the Heptio AWS Quick Start.  This is where active development is happening.

Details of the Quick Start are in this [Heptio Blog post](https://blog.heptio.com/aws-quickstart-for-kubernetes-26ccaf7e1c8f#.aqb0bit5l)

Amazon's page for this is [here](https://aws.amazon.com/quickstart/architecture/heptio-kubernetes/).

This will be updated and pushed regularly to https://github.com/aws-quickstart/quickstart-heptio.

## Deploying

The canonical way to deploy this Quick Start is by following the "Deploy on AWS into a new VPC" link on this project's [AWS Quick Start Page](https://aws.amazon.com/quickstart/architecture/heptio-kubernetes/).

You can see what's behind that link by checking AWS's fork of Heptio's repository at https://github.com/aws-quickstart/quickstart-heptio.  The `master` branch of github.com/heptio/aws-quickstart is merged into AWS's repository and deployed to the Quick Start page on a monthly basis.

You can also deploy the Quick Start via the command line:

```
# Where to place your cluster
REGION=us-west-2
AZ=us-west-2b

# What to name your CloudFormation stack
STACK=Heptio-Kubernete

# Which SSH key you want to allow access to the cluster
KEYNAME=mykey

# Import an SSH public key (or skip this command and create/import an SSH key pair in the AWS console)
aws ec2 --region $REGION import-key-pair --key-name $KEYNAME --public-key-material "$(cat ~/.ssh/id_rsa.pub)"

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

aws cloudformation create-stack \
  --region $REGION \
  --stack-name $STACK \
  --template-url "https://quickstart-reference.s3.amazonaws.com/heptio/latest/templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS \
  --capabilities=CAPABILITY_IAM
```

### Deploying latest master

If you want to try changes from this repository before they are released into AWS's Quick Start page, just change the Template URL, `QSS3BucketName`, and `QSS3KeyPrefix` to their development equivalents.

```
# This is where Heptio stores templates/scripts for the master branch of this repository
S3_BUCKET=heptio-aws-quickstart-test
S3_PREFIX=heptio/kubernetes/master

# Where to place your cluster
REGION=us-west-2
AZ=us-west-2b

# What to name your CloudFormation stack
STACK=Heptio-Kubernetes

# What SSH key you want to allow access to the cluster (must be created ahead of time in your AWS EC2 account)
KEYNAME=mykey

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

aws cloudformation create-stack \
  --region $REGION \
  --stack-name $STACK \
  --template-url "https://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}/templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AZ \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS \
    ParameterKey=QSS3BucketName,ParameterValue=${S3_BUCKET} \
    ParameterKey=QSS3KeyPrefix,ParameterValue=${S3_PREFIX} \
  --capabilities=CAPABILITY_IAM
```

### Testing local changes

To deploy your own changes manually from source, you'll need to upload the contents of the `scripts` and `templates` directories to S3, and configure your CloudFormation to use those S3 URL's.

If you're making changes to things like the Kubernetes version or anything installed in the base AMI, you'll also need to rebuild the AMI with Wardroom.  See the "Local development" section below for more details.

Optionally, aws-quickstart also supports overriding a few select kubernetes binaries (kubelet, kubeadm, kubectl) at runtime for development purposes.  To replace these binaries at runtime, simply place your custom versions into the `$S3_PREFIX/bin/` folder:
```
$ aws s3 ls s3://quickstart/overrides/bin/
2017-09-08 13:04:02   71453136 kubeadm
2017-09-08 12:58:27   72501019 kubectl
2017-09-08 12:58:27  146464528 kubelet
```
These will be downloaded during cloudformation initialization and subsequently become available to the running instance.

An example deployment:

```
S3_BUCKET=your-s3-bucket

# Where "path/to/your/files" is the directory in S3 under which the templates and scripts directories will be placed
S3_PREFIX=path/to/your/files

# Where to place your cluster
REGION=us-west-2
AVAILABILITY_ZONE=us-west-2b

# What you want to call your CloudFormation stack
STACK=my-kubernetes-cluster

# What SSH key you want to allow access to the cluster (must be created ahead of time in your AWS EC2 account)
KEYNAME=mykey

# What IP addresses should be able to connect over SSH and over the Kubernetes API
INGRESS=0.0.0.0/0

# Copy the files from your local directory into your S3 bucket
aws s3 sync --acl=public-read ./templates s3://${S3_BUCKET}/${S3_PREFIX}/templates/
aws s3 sync --acl=public-read ./scripts s3://${S3_BUCKET}/${S3_PREFIX}/scripts/

aws cloudformation create-stack \
  --region $REGION \
  --stack-name $STACK \
  --template-url "https://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}/templates/kubernetes-cluster-with-new-vpc.template" \
  --parameters \
    ParameterKey=AvailabilityZone,ParameterValue=$AVAILABILITY_ZONE \
    ParameterKey=KeyName,ParameterValue=$KEYNAME \
    ParameterKey=QSS3BucketName,ParameterValue=$S3_BUCKET \
    ParameterKey=QSS3KeyPrefix,ParameterValue=$S3_PREFIX \
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS \
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

## Local development

This Quick Start is developed as a set of AWS CloudFormation templates. This is
a brief overview of the files in this repo, for more architecture details see
the [Deployment
Guide](https://s3.amazonaws.com/quickstart-reference/heptio/latest/doc/heptio-kubernetes-on-the-aws-cloud.pdf)

**The `templates` directory**:

- `kubernetes-cluster.template` sets up the resources that the Kubernetes
  cluster depends on. Mainly this is the API load balancer, the master node, the
  auto-scaling group of kubelet nodes, and the various security groups required
  to allow them to talk to one another. The nodes in this template are created
  from a base AMI, which you can recreate using
  [wardroom](https://github.com/heptiolabs/wardroom).
- `kubernetes-cluster-with-new-vpc.template` sets up a new VPC with a public and
  private subnets, and calls out to `kubernetes-cluster.template` as a
  sub-stack.

**The `scripts` directory**:

This contains files that required by the templates. This is to avoid inlining a
lot of text directly in the template files. Templates access files from this
directory by referencing their S3 URL's, which is why this directory and the
`templates` directory both need to be copied into S3 in order to be used.

Some notable files in this directory:

- `setup-k8s-master.sh.in`: This file is run by the master node on first boot as
  part of its initialization. It is a [Mustache
  template](https://mustache.github.io/) file, with template variables that are
  set by the `kubernetes-cluster.template` template. Note that this template
  file does not install the Kubernetes binaries, those are baked into the AMI as
  part of Wardroom.
- `calico.yaml`, `weave.yaml`: These are networking add-ons which are applied
  with `kubectl` by the master after the Kubernetes cluster is initialized.
