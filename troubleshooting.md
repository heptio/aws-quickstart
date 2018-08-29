# Troubleshooting

In addition to the [documentation](http://docs.heptio.com/content/aws.html) available for the Heptio AWS Quick Start, this page outlines some troubleshooting tips if you're running into issues with your quick start.

## Quick Start fails during stack creation

During the creation of the AWS stack for the Heptio Kubernetes Quick-Start, the following error is observed in the CloudFormation logs:

```
CREATE_FAILED AWS::CloudFormation::Stack K8sStack Requires capabilities : [CAPABILITY_IAM]
```

Make sure on the final page of the CloudFormation wizard (titled Review), that the last section on the page (titled Capabilities) has the checkbox marked before clicking Create. The checkbox asks the user to allow the template to create IAM resources.

## Quick Start CloudFormation Master Does Not Start Properly

This can occur for multiple reasons and often requires investigating logs on the failed master instance. The first hurdle is keeping the failed resources around. The cloud formation default option in AWS is to Rollback on failure. When using the console you can disable this by going to `Advanced` and then setting `Rollback on failure` to `No`.

Once you're able to access the failed kubernetes master the appropriate logs are found in /var/log. The two most important logs are cfn-init.log and cfn-init-cmd.log. These two logs show the cloud formation process in depth.

An alternative place to view the cfn-init-cmd.log is the CloudWatch Logs group `Heptio-Kubernetes-K8sStack-<stack identifier number>`. This log group is automatically created by the CloudFormation template. This CloudWatch logs group contains the live cloud-init-cmd.log file. This log file is available from the the nodes we provision minus the bastion host. This logs group is automatically removed when a rollback or deletion of the stack is done.

## Quick Start CloudFormation Stack Does Not Delete Properly

This is typically caused when certain additional resources are created inside the stack's VPC, like Elastic Load Balancers.  Kubernetes creates these when you create a [Service](https://kubernetes.io/docs/concepts/services-networking/service/) with `type: LoadBalancer`.

This is a known issue with the way CloudFormation stacks work, and the only workaround is to delete the Load Balancers manually.

One way to clean up all load balancers in your VPC is to use the AWS CLI.

### Deleting Elastic Load Balancers using the AWS CLI

You will need the VPC ID that was created along with your CloudFormation stack, which you can find in the [CloudFormation UI](https://console.aws.amazon.com/cloudformation) under the "Resources" tab when you select the stack that is failing to delete.

These commands will delete all load balancers in the stack.  (Warning: this is destructive, so be sure you only do this if you want to delete everything created by the Quick Start!):

```
# Set to the VPC that you want to delete. Example: vpc-1234abcd
export VPC_ID='<vpc-id>'
# Set to the region in which you created the Quick Start.  Example: us-west-1
export AWS_DEFAULT_REGION='<aws-region>'

aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId == \`${VPC_ID}\`].LoadBalancerName" --output text \
    | xargs -n 1 echo \
    | while read lb; do
          aws elb delete-load-balancer --load-balancer-name="${lb}"
      done
```

Then you should be able to delete the CloudFormation stack normally.

**Note**: The process of freeing some of the resources associated with the Load Balancers is asynchronous, so it may take some time before the stack can be fully deleted.

## Deploying into an existing VPC

The initialization step of `kubeadm`, `kubeadm init` requires your node to be
resolvable via DNS.

If you are deploying this stack into an existing VPC that uses AmazonProvidedDNS
as the domain name servers, you will have to make sure to add the correct domain
name as well. If you're running in us-east-1 add `ec2.internal`. Otherwise, add
`<region>.compute.internal` where `<region>` is us-west-2, us-east-2, etc.