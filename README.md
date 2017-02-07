##Release Notes:

* [x] Use Calico instead of Weave for networking between pods

* [x] Use auto recovery for master node

##TODO:

* [ ] Wrap everything in a VPC with private/public subnets and a Bastion host << AWS

* [ ] Generate the cluster key from a script << AWS

* [ ] Auth ID << AWS

* [ ] Finish formatting the repo so we can get deep feedback on the PDF << AWS

* [ ] Integrate with `--cloud-provider` so we make better use of AWS resources.  We should be able to attach an EBS volume to a pod and we should be able to use service with type=loadbalancer. << Heptio

* [ ] Improve our suggested test case; `sock-shop` doesn't test everything << Heptio

* [ ] Research Cloudwatch integration << Heptio

* [ ] Make a YAML version of the CF template so we can comment it << Heptio

* [ ] Show how to extract credentials so you can access the cluster from your laptop without ssh to a VM << Heptio

* [ ] Show how to upload images to the AWS registry and use them with k8s cluster (That will enable the core flow of "build a container, push it to registry, launch on k8s") << Heptio

* [ ] Make sure all the nodes are in the same AZ << Heptio

* [ ] Advise users to run multiple clusters for a multi-AZ setup << Heptio