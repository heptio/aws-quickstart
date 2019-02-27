# Run Kubernetes on Amazon Web Services (AWS)

_Using EC2 Instances, Auto Recovery, Load Balancing, and an Auto Scaling Group with CloudFormation and the AWS CLI_

![../../_images/banner-twitter.jpg][1]

## Introduction

Follow this tutorial to run Kubernetes on Amazon Web Services (AWS). This tutorial uses the AWS CLI to launch your stack from the Heptio [Quick Start for Kubernetes][2] CloudFormation template.

[Kubernetes][3] is the popular orchestration software used for managing cloud workloads through containers (like Docker).

Kubernetes helps assign containers to machines in a scalable way, keep them running in the face of failures and facilitating them talking to each other.

The AWS Cloud provides the infrastructure services your containerized workloads run on, while Kubernetes coordinates the containers in a flexible and fault-tolerant way. Kubernetes handles many of the details of traditional system administration and decouples workload deployment from infrastructure deployment.

We'll suggest sane defaults for both Kubernetes and AWS. However, keep in mind that Kubernetes is a fast-moving project, and this stack is appropriate for proof of concept (PoC), experimentation, development, and small internal-facing projects. Consider this a test drive.

This stack does not currently support upgrades and must be rebuilt for new versions.

This tutorial assumes you're fairly new to Kubernetes and an AWS power user (familiar with the CLI and CloudFormation).

## Quick start

This stack uses the [CloudFormation template at this link][4].

Or, [click here][5] to load the template in the CloudFormation console directly. Then, read the [AWS Quick Start PDF][2] to follow along with stack creation.

Create your stack:
    
    
    STACK=varMyStack
    TEMPLATEPATH=https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template
    AZ=varMyAvailabilityZone
    INGRESS=0.0.0.0/0
    KEYNAME=varMyKeyName
    
    aws cloudformation create-stack --stack-name $STACK 
    --template-body $TEMPLATEPATH 
    --capabilities CAPABILITY_NAMED_IAM 
    --parameters ParameterKey=AvailabilityZone,ParameterValue=$AZ 
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS 
    ParameterKey=KeyName,ParameterValue=$KEYNAME
    

## Architecture and decisions

This CloudFormation template [(download)][4] [(launch)][5] creates two stacks: one that builds a wrapper virtual private cloud (VPC), and one that deploys the Kubernetes cluster into it. For advanced AWS users, you can [deploy just the Kubernetes stack][6] into your existing AWS architecture. This architecture list is for the template that creates a new VPC for your Kubernetes cluster.

The Quick Start builds Kubernetes 1.8.2.

* A VPC in a single Availability Zone
* 2 subnets, one public and one private
* 1 EC2 instance acting as a bastion host in the public subnet
* 1 EC2 instance with automatic recovery for the master node in the private subnet
* 1-20 EC2 instances in an Auto Scaling Group for additional nodes in the private subnet (2 with default settings)
* 1 ELB load balancer for HTTPS access to the Kubernetes API
* Ubuntu 18.04 LTS for all nodes; the [base image][7] is a [custom AMI][8] based on Ubuntu 16.04
* 40 GiB of disk for the EC2 instances
* [kubeadm][9] for bootstrapping Kubernetes on Linux
* [Docker][10] for the container runtime, which Kubernetes depends on
* [Calico][11] or [Weave][12] for pod networking
* One stack-only security group that allows port 22 for SSH access from the bastion host, port 6443 for HTTPS access to the API, and inter-node connectivity on all ports

The templates are built for [CloudFormation][13].

## 1\. Determine Availability Zone, admin ingress location, and SSH key

Collect the following information to pass to the template.

* Your [Availability Zone][14], which should be something like `us-west-2a`.
* The CIDR block (IP address range) from which you would like to allow SSH access to the bastion host and HTTPS access to the Kubernetes API. Use 0.0.0.0/0 to allow access from all locations.
* The name of the SSH [EC2 KeyPair][15] you created as part of the prerequisites.

## 2\. Create stack from CloudFormation template with AWS CLI

This [template][4] is created and maintained by Heptio.

Run this command to create your AWS stack with default options:
    
    
    STACK=varMyStack
    TEMPLATEPATH=https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template
    AZ=varMyAvailabilityZone
    INGRESS=0.0.0.0/0
    KEYNAME=varMyKeyName
    
    aws cloudformation create-stack --stack-name $STACK 
    --template-body $TEMPLATEPATH 
    --capabilities CAPABILITY_NAMED_IAM 
    --parameters ParameterKey=AvailabilityZone,ParameterValue=$AZ 
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS 
    ParameterKey=KeyName,ParameterValue=$KEYNAME
    

Required parameters:

| ----- |
| STACK: | Required. Enter any name you want to use to identify this new AWS Stack where `varMyStack` is shown above. |  
| TEMPLATEPATH: | `https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template` is the location of the CloudFormation template. |  
| AZ: | Required. Your [Availability Zone (AZ)][14] should be something like `us-west-2a`. Choose an AZ that matches your region. |  
| INGRESS: | `0.0.0.0/0` allows SSH access and HTTPS access to the Kubernetes API from any and all locations. Change the value to be more restrictive to your location for better security. |  
| KEYNAME: | Required. Replace `varMyKeyName` with the name of an [existing EC2 KeyPair][15], to enable SSH access to the cluster. | 

The command requires `\--capabilities CAPABILITY_NAMED_IAM` so that the cluster will be able to provision its own AWS resources, like storage and load balancing, as part of its operation.

The template automatically selects your default AWS Region.

You'll receive the StackId following a successful deployment:
    
    
    {
    "StackId": "arn:aws:cloudformation:us-west-2:056999937450:stack/varMyStack/11ab4060-fc5e-11e6-a5b2-503aca41a08d"
    }
    

After successfully deploying a stack from this template, you've got a working Kubernetes cluster. If that's all you needed, you can stop here. We recommend that you next [set up WordPress with Helm][16] as a demo application to explore your new cluster.

The rest of the optional steps show you more information about your stack and your cluster and help verify that everything works. Next we'll take a look at the AWS resources you just deployed and view information about your stack.

## 3\. (Optional) View stack information

Let's take a look at the stack we've just created.

We'll use Amazon's `describe-stacks` command (read more in the [AWS docs][17]). Use the stack name for `varMyStack`.
    
    
    STACK=varMyStack
    
    aws cloudformation describe-stacks --stack-name $STACK
    

You'll see a fair bit of output, including all the parameters we entered and the template output.

## 4\. (Optional) Download kubectl configuration

One useful output from the `describe-stacks` command is the `GetKubeConfigCommand`.
    
    
    STACK=varMyStack
    
    aws cloudformation describe-stacks --query 'Stacks[*].Outputs[?OutputKey == `GetKubeConfigCommand`].OutputValue' --output text --stack-name $STACK
    

[kubectl][18] is a command-line tool for managing your cluster. You'll need a configuration file for kubectl, containing the unique connection information for your Kubernetes cluster, if you want to use your local copy to manage your Kubernetes cluster.

If you prefer not to install kubectl locally, it is also installed on the master node (see the next section for SSH connection information).

The command shown in the `describe-stacks` output will securely copy a file called `kubeconfig` that was automatically generated on the master node and contains connection information and credentials for the cluster. The command to download the file should look something like this:
    
    
    SSH_KEY="path/to/varMyKey.pem"; scp -i $SSH_KEY -o ProxyCommand="ssh -i "${SSH_KEY}" ubuntu@111.111.111.111 nc %h %p" ubuntu@10.0.0.0:~/kubeconfig ./kubeconfig
    

Let's run the above `scp` command now. You must supply the path to `path/to/varMyKey.pem`, which is the private half of the EC2 KeyPair you chose for your `KEYNAME` above.

Enter `yes` at both prompts if this is your first time connecting to the cluster. You may see the output `Killed by signal 1.` because we are proxying; this is fine.

Set this local environment variable so kubectl uses the downloaded file:
    
    
    export KUBECONFIG=$(pwd)/kubeconfig
    

Or, if you don't mind overwriting a possible existing config file for kubectl, you can copy the downloaded file to `cp $(pwd)/kubeconfig ~/.kube/config`. That's the default config file for kubectl, so it will use this configuration automatically without needing the `export` command.

## 5\. (Optional) SSH to the cluster

The `SSHProxyCommand` is another useful excerpt from the `describe-stacks` output.
    
    
    STACK=varMyStack
    
    aws cloudformation describe-stacks --query 'Stacks[*].Outputs[?OutputKey == `SSHProxyCommand`].OutputValue' --output text --stack-name $STACK
    

It shows a command that lets us SSH to the bastion host on its public IP address, and proxy to the master node on its private IP. In short, this command lets us SSH to the master node:
    
    
    SSH_KEY="path/to/varMyKey.pem"; ssh -i $SSH_KEY -A -L8080:localhost:8080 -o ProxyCommand="ssh -i "${SSH_KEY}" ubuntu@111.111.111.111 nc %h %p" ubuntu@10.0.0.0
    

Let's connect now by running the command above. You must supply the path to `path/to/varMyKey.pem`, which is the private half of the EC2 KeyPair you chose for your `KEYNAME` above.

Enter `yes` at both prompts if this is your first time connecting to the cluster.

You are now connected to the master node of the Kubernetes cluster over SSH.

You'll may see the output `Killed by signal 1.` after you exit, because we are proxying; this is fine.

We'll look at one more output before moving on: the command to add more nodes to your cluster.

## 6\. (Optional) Connect more nodes to the cluster

To add more nodes to this cluster in the future, you can either:

To join more nodes manually, use the cluster token that was generated while creating the stack. You'll have to [install kubeadm][9] on each node, and then run the join command as **root** from the **new node(s)**. First, let's get our `join` command with the unique token for this cluster:
    
    
    aws cloudformation describe-stacks --stack-name $STACK | grep -A 2 -B 2 JoinNodes
    
    
    
    "Outputs": [
      {
      "Description": "Command to join more nodes to this cluster.",
      "OutputKey": "JoinNodes",
      "OutputValue": "kubeadm join --token=xxxxxx.xxxxxxxxxxxxxxxx 10.0.0.0"
      }
    

Now, run the join command on the new node(s). Replace `xxxxxx.xxxxxxxxxxxxxxxx` with your cluster token and `10.0.0.0` with the private IP address of the master node. (You can view the private IP address using the `describe-stacks` command shown earlier.)
    
    
    CLUSTERTOKEN=xxxxxx.xxxxxxxxxxxxxxxx
    PRIVATEIP=10.0.0.0
    
    kubeadm join --token=$CLUSTERTOKEN $PRIVATEIP
    

## 7\. (Optional) View resource information

Show resource information, using the `describe-stack-resources` option (read more in the [AWS docs][19]):
    
    
    STACK=varMyStack
    
    aws cloudformation describe-stack-resources --stack-name $STACK
    

This shows the details of all resources created for this stack. Below is an excerpt showing the security group that was created to allow SSH access:
    
    
    {
      "StackResources": [
      ...
      {
      "StackId": "arn:aws:cloudformation:us-west-2:056999937450:stack/varMyStack/11ab4060-fc5e-11e6-a5b2-503aca41a08d",
      "ResourceStatus": "CREATE_COMPLETE",
      "ResourceType": "AWS::EC2::SecurityGroup",
      "Timestamp": "2017-02-26T20:00:33.290Z",
      "StackName": "varMyStack",
      "PhysicalResourceId": "sg-ce580eb6",
      "LogicalResourceId": "BastionSecurityGroup"
      }
      ]
    }
    

Now that we've looked at the AWS details, let's make sure Kubernetes works as expected. The next section shows how to check that the proper number of nodes were connected.

## 8\. (Optional) Verify cluster

Complete one of the following earlier steps to connect to your cluster:

* Download kubectl Configuration
* SSH to the Cluster

Whether you choose the local kubectl configuration or to SSH to your cluster, you should now be on a device where you can run [kubectl][18] commands for this cluster.

Use `kubectl` to list the connected nodes.

With our defaults, we should see one master node and two additional nodes.
    
    
    NAME               STATUS         AGE
    ip-10-0-0-0     Ready,master      1h
    ip-172-172-172-172 Ready          1h
    ip-192-192-192-192 Ready          1h
    

Now that we've seen the Kubernetes cluster working, let's check on our ability to deploy an application so Kubernetes is doing something interesting.

## Reference: The stack creation command
    
    
    STACK=varMyStack
    TEMPLATEPATH=https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template
    AZ=varMyAvailabilityZone
    INGRESS=0.0.0.0/0
    KEYNAME=varMyKeyName
    NETWORKPROV=calico
    NODECAPACITY=2
    INSTANCE=t2.medium
    DISK=40
    INSTANCEBASTION=t2.micro
    S3BUCKET=heptio-aws-quickstart-test
    S3KEY=heptio/kubernetes/latest
    
    aws cloudformation create-stack --stack-name $STACK 
    --template-body $TEMPLATEPATH 
    --capabilities CAPABILITY_NAMED_IAM 
    --parameters ParameterKey=AvailabilityZone,ParameterValue=$AZ 
    ParameterKey=AdminIngressLocation,ParameterValue=$INGRESS 
    ParameterKey=KeyName,ParameterValue=$KEYNAME 
    ParameterKey=NetworkingProvider,ParameterValue=$NETWORKPROV 
    ParameterKey=K8sNodeCapacity,ParameterValue=$NODECAPACITY 
    ParameterKey=InstanceType,ParameterValue=$INSTANCE 
    ParameterKey=DiskSizeGb,ParameterValue=$DISK 
    ParameterKey=BastionInstanceType,ParameterValue=$INSTANCEBASTION 
    ParameterKey=QSS3BucketName,ParameterValue=$S3BUCKET 
    ParameterKey=QSS3KeyPrefix,ParameterValue=$S3KEY
    

Parameters:

| ----- |
| STACK: | Required. Enter any name you want to use to identify this new AWS Stack where `varMyStack` is shown above. |  
| TEMPLATEPATH: | `https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template` is the location of the CloudFormation template. |  
| CAPABILITY_NAMED_IAM: | This value is already set and should remain unchanged. This acknowledges that the stack can create more resources, such as a load balancer or Elastic Block Store (EBS) volume. Additional resources created from Kubernetes will be billed to your AWS account. |  
| AZ: | Required. Your [Availability Zone (AZ)][14] should be something like `us-west-2a`. Choose an AZ that matches your region. |  
| INGRESS: | `0.0.0.0/0` allows SSH access and HTTPS access to the Kubernetes API from any and all locations. Change the value to be more restrictive to your location for better security. |  
| KEYNAME: | Required. Replace `varMyKeyName` with the name of an [existing EC2 KeyPair][15], to enable SSH access to the cluster. |  
| NETWORKPROV: | Replace `calico` with the networking provider to use for communication between pods in the Kubernetes cluster. Supported configurations are [calico][11] and [weave][12]. |  
| NODECAPACITY: | Not required. 1-20 nodes, default `2`. The initial number of nodes that will run workloads (in addition to the master node instance). You can scale up your cluster later with more nodes. |  
| INSTANCE: | Not required. Default is `t2.medium`. [EC2 instance type][20] for the cluster. |  
| DISK: | Not required. Default is `40`. The size of the root disk for the EC2 instances for the cluster, in GiB. You can specify a value between 8 and 1024. |  
| INSTANCEBASTION: | Not required. Default is `t2.micro`. [EC2 instance type][20] for the bastion host, which allows traffic from the location set in `INGRESS` to the cluster. |  
| S3BUCKET: | Not required. Default is `heptio-aws-quickstart-test`. Change this setting only if you've set up assets, like your own networking configuration, in an S3 bucket. This and the next parameter let you access scripts from the scripts/ and templates/ directories of your own fork of Heptio's Quick Start assets, uploaded to S3 and stored at ${bucketname}.s3.amazonaws.com/${prefix}/scripts/somefile.txt. The Quick Start bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-). |  
| S3KEY: | Not required. Default is `heptio/kubernetes/latest`. Change this setting only if you've set up assets, like your own networking configuration, in an S3 bucket. This and the previous parameter let you access scripts from the scripts/ and templates/ directories of your own fork of Heptio's Quick Start assets, uploaded to S3 and stored at ${bucketname}.s3.amazonaws.com/${prefix}/scripts/somefile.txt. The Quick Start key prefix can include numbers, lowercase letters, uppercase letters, hyphens (-), and forward slashes (/). It cannot start or end with a forward slash (/), which is because they are automatically appended. | 

[1]: http://docs.heptio.com/_images/banner-twitter.jpg
[2]: https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/doc/vmware-kubernetes-on-the-aws-cloud.pdf
[3]: http://kubernetes.io/
[4]: https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template
[5]: https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=k8s&templateURL=https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster-with-new-vpc.template
[6]: https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=k8s&templateURL=https://aws-quickstart.s3.amazonaws.com/quickstart-vmware/templates/kubernetes-cluster.template
[7]: https://github.com/heptio/aws-quickstart/tree/master/packer
[8]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
[9]: http://kubernetes.io/docs/getting-started-guides/kubeadm/
[10]: https://www.docker.com/
[11]: https://www.projectcalico.org/calico-networking-for-kubernetes/
[12]: https://github.com/weaveworks-experiments/weave-kube
[13]: https://aws.amazon.com/cloudformation/
[14]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#using-regions-availability-zones-describe
[15]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
[16]: tutorial-wordpress.md
[17]: http://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html
[18]: https://kubernetes.io/docs/user-guide/prereqs/
[19]: http://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stack-resources.html
[20]: https://aws.amazon.com/ec2/instance-types/