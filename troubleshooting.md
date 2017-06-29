# Troubleshooting

In addition to the [documentation](http://docs.heptio.com/content/aws.html) available for the Heptio AWS Quick Start, this page outlines some troubleshooting tips if you're running into issues with your quick start.

## Quick Start CloudFormation Stack Does Not Delete Properly

This is typically caused when certain additional resources are created inside the stack's VPC, like Elastic Load Balancers.  Kubernetes creates these when you create a [Service](https://kubernetes.io/docs/concepts/services-networking/service/) with `type: LoadBalancer`.

This is a known issue with the way CloudFormation stacks work, and the only workaround is to delete the Load Balancers manually.

One way to clean up all load balancers in your VPC is to use the AWS CLI.

### Deleting Elastic Load Balancers using the AWS CLI

You will need the VPC ID that was created along with your CloudFormation stack, which you can find in the [CloudFormation UI](https://console.aws.amazon.com/cloudformation) under the "Resources" tab when you select the stack that is failing to delete.

These commands will delete all load balancers in the stack.  (Warning: this is destructive, so be sure you only do this if you want to delete everything created by the Quick Start!):

```
# Set to the VPC that you want to delete. Example: vpc-1234abcd
export VPC_IC='<vpc-id>'
# Set to the region in which you created the Quick Start.  Example: us-west-1
export AWS_DEFAULT_REGION='<aws-region>'

aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId == \`${VPCID}\`].LoadBalancerName" --output text \
    | xargs -n 1 echo \
    | while read lb; do
          aws elb delete-load-balancer --load-balancer-name="${lb}"
      done
```

Then you should be able to delete the CloudFormation stack normally.

**Note**: The process of freeing some of the resources associated with the Load Balancers is asynchronous, so it may take some time before the stack can be fully deleted.
