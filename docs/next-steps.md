# Welcome to the Next Steps for your Kubernetes cluster.

This guide is for [Kubernetes Quick Start](https://aws.amazon.com/quickstart/) admins and users. This guide assumes you have deployed the Kubernetes Quick Start by walking through [Amazon’s Quick Start PDF](https://s3.amazonaws.com/quickstart-reference/vmware/latest/doc/vmware-kubernetes-on-the-aws-cloud.pdf), which uses Amazon’s CloudFormation console.

Now that you have your Kubernetes stack on Amazon, we recommend setting up [WordPress with Helm](tutorial-wordpress.md) as a demo application to explore your new cluster.


> Note:
>
>This stack is appropriate for proof of concept (PoC), experimentation, development, and small internal-facing projects. Consider this a test drive.
>
>This stack does not currently support upgrades and must be rebuilt for new versions.


## Release notes
Release notes: AWS Quick Start for Kubernetes by VMware

The Quick Start builds Kubernetes 1.13.2.

## Next steps
If you’ve completed the Kubernetes Quick Start on AWS, we recommend that you try these next steps:

 - Check that your cluster is configured and working as expected by running [Sonobuoy](https://github.com/heptio/sonobuoy) against your cluster. Sonobuoy provides cluster diagnostics by running Kubernetes conformance tests.
 - Explore your cluster and deploy a demo application: [WordPress with Helm](tutorial-wordpress.md)
 - Allow traffic: [Allow outside traffic to your cluster with load balancing](tutorial-traffic.md)

## Additional resources
 VMware has collected some links to help you explore your Kubernetes cluster:

- Bitnami shows how to deploy a MEAN stack: [Deploy, Scale And Upgrade An Application On Kubernetes With Helm](https://docs.bitnami.com/kubernetes/how-to/deploy-application-kubernetes-helm/)
 - Bitnami manages a library of [Kubernetes-ready applications](https://kubeapps.com/)
 - Project Calico goes into detail on networking for Kubernetes: [Calico for Kubernetes](https://docs.projectcalico.org/v3.5/getting-started/kubernetes/)

## Architecture and decisions
This CloudFormation template [(download)](https://s3.amazonaws.com/quickstart-reference/vmware/latest/templates/kubernetes-cluster-with-new-vpc.template) [(launch)](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=k8s&templateURL=https://s3.amazonaws.com/quickstart-reference/vmware/latest/templates/kubernetes-cluster-with-new-vpc.template) creates two stacks: one that builds a wrapper virtual private cloud (VPC), and one that deploys the Kubernetes cluster into it. For advanced AWS users, you can [deploy just the Kubernetes stack](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/new?stackName=k8s&templateURL=https://s3.amazonaws.com/quickstart-reference/vmware/latest/templates/kubernetes-cluster.template) into your existing AWS architecture. This architecture list is for the template that creates a new VPC for your Kubernetes cluster.

The Quick Start builds Kubernetes 1.13.2.

 - A VPC in a single Availability Zone
 - 2 subnets, one public and one private
 - 1 EC2 instance acting as a bastion host in the public subnet
 - 1 EC2 instance with automatic recovery for the master node in the private subnet
 - 1-20 EC2 instances in an Auto Scaling Group for additional nodes in the private subnet (2 with default settings)
 - 1 ELB load balancer for HTTPS access to the Kubernetes API
 - Ubuntu 18.04 LTS for all nodes; the [base image](https://github.com/heptio/aws-quickstart/tree/master/packer) is a [custom AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) based on Ubuntu 18.04
 - 40 GiB of disk for the EC2 instances
 - [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/) for bootstrapping Kubernetes on Linux
 - [Docker](https://www.docker.com/) for the container runtime, which Kubernetes depends on
 - [Calico](https://www.projectcalico.org/calico-networking-for-kubernetes/) or [Weave](https://github.com/weaveworks-experiments/weave-kube) for pod networking
 - One stack-only security group that allows port 22 for SSH access from the bastion host, port 6443 for HTTPS access to the API, and inter-node connectivity on all ports
 - The templates are built for [CloudFormation](https://aws.amazon.com/cloudformation/).