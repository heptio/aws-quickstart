##Release Notes:

* [x] Use Calico instead of Weave for networking between pods

* [x] Use auto recovery for master node

##TODO:

* [ ] Wrap everything in a VPC

* [ ] Generate the cluster key from a script

* [ ] Auth ID

* [ ] Finish formatting the repo so we can get deep feedback on the PDF

* [ ] Integrate with `--cloud-provider` so we make better use of AWS resources.  We should be able to attach an EBS volume to a pod and we should be able to use service with type=loadbalancer.

* [ ] Improve our suggested test case; `sock-shop` doesn't test everything

* [ ] Research Cloudwatch integration
