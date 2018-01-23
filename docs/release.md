# Quickstart Release Guide

## Purpose

This guide will walk you through creating a new release of Quickstart, starting
with creating a new golden AMI image. This procedure should be used for new releases
of Kubernetes, OS-level security patches, and any other updates that require a new
image. 

## Playbook


### 1. Build a new AMI using wardroom

[Wardroom][wardroom] is a tool used to make Kubernetes-ready AMIs for use with
the quickstart. The first step in a new quickstart image is building the image
in Wardroom.

* Checkout [`github.com/heptiolabs/wardroom`][wardroom].
* You'll need Amazon creds in the environment. [aws-vault][vault] is useful for
  this. If you use vault, preface the following commands with something like
  `aws-vault exec <profile name> --`
* Make you are on a clean tree, preferably the origin's `master`.
  ```
  $ git status
  On branch master
  Your branch is up to date with 'origin/master'.

  nothing to commit, working tree clean
  ```
* Build the Packer image. [The repo has detailed instructions][packer], but the
  basic command is something like `packer build -var-file us-east-1.json -var
  kubernetes_version=1.9.2-00 -var kubernetes_cni_version=0.6.0-00 -var
  build_version=$(git rev-parse HEAD) -only ami-ubuntu-16.04 packer.json`.
* Boot an instance with the image you created, just to verify that everything
  worked. If you have the [`aws` cli][aws], you can run something like: `aws
  ec2 run-instances --image-id <your ami ID> --instance-type t1.micro --region
  us-east-1 --key-name <aws keypair> --security-groups <security group>`. Make
  sure `<security group>` allows SSH to your node. `aws ec2 describe-instances
  --instance-ids i-02cedcd163ae3a8ba | grep -i public` will get you the IP/DNS
  name. Then you can SSH in with `ssh -i <your pem file> ubuntu@<public ip or
  DNS>`.
* Make sure the instance has the version of kubernetes you expect, and any other
  changes you're making. If it doesn't, fix it and rebuild packer.

[wardroom]: https://github.com/heptiolabs/wardroom
[vault]: https://github.com/99designs/aws-vault
[packer]: https://github.com/heptiolabs/wardroom/tree/master/packer#building-images
[aws]: https://aws.amazon.com/cli/


### 2. Publish the AMIs. 

Once you're happy with your AMI, it's time to copy the AMI to the other regions
and make it public.

* Again, Wardroom has [more detailed instructions][packer], but the basic
  pattern is `python3 setup.py install` in the packer directory. Then `copy-ami
  -i ami-78476f02 -r us-east-1`.
* This process takes quite a while. However, early on it will emit
  some YAML which can be used in Step 3.

[packer]: https://github.com/heptiolabs/wardroom/tree/master/packer#building-images

### 3. Update the Quickstart template.

Now that you have the new AMIs, you'll need to tell Quickstart about it.

* Edit the [quickstart template][template] with your favourite editor.
* Delete the previous AMI list, and paste the YAML you got from step 3.
* Now edit the [wardroom.json][wardroom]. Update the hash with the hash from
  packer, then the version information if necessary.

[template]: https://github.com/heptio/aws-quickstart/blob/master/templates/kubernetes-cluster.template#L309
[wardroom]: https://github.com/heptio/aws-quickstart/blob/master/wardroom.json
### 4. PR the changes. 

The CI for `aws-quickstart` serves two purposes. One, it will validate the
information in [`wardroom.json`][wardroom] is present and correct in all AMIs.
Two, it will boot a cloudformation template and run a smoke test with Sonobuoy.

Don't move on to the next step until both tests pass.

[wardroom]: https://github.com/heptio/aws-quickstart/blob/master/wardroom.json

### 5. Manually boot a cloud and do a full Sonobuoy run against it.

The smoke test is good, but before a full release is done there should be a full
sonobuoy run. Unfortunately, you'll have to set this up yourself.

* Follow the instructions for [Testing local changes][testing]. You may need to
  create a new S3 bucket (`aws s3 mb`).
* You can follow the boot on the command line, but you'll have an easier time of
  it on the AWS web console. Log in, switch to the region you're using, and
  navigate to cloudformation.
* Once it's booted, look in the `Outputs` section for the outer formation (the
  one without the random) characters at the end.
* Find the `GetKubeConfigCommand` output, and copy it to a terminal. Sub in your
  private key pair and run the command to get a kubeconig.
* Validate your new config with `KUBECONFIG=./kubeconfig kubectl get nodes`.
* Go to [scanner][scanner] and get a manifest.
* Apply it with your new config: `KUBECONFIG=./kubeconfig kubectl apply -f
  https://scanner.heptio.com/...`
* Go get some coffee. This'll be a while.
* Once it's done, if it's a success, paste the results URL into your PR.
* Terminate the cluster

[testing]: https://github.com/heptio/aws-quickstart#testing-local-changes
[scanner]: https://scanner.heptio.com/

### 6. Send a PR to Amazon.

The way the quickstart makes its way to Amazon is by PRing to Amazon's [upstream
repo][amazon].

* Open a PR from Heptio's repo to the [Amazon repo][amazon]. Important: PRs
  should be sent to the `develop` branch, not the `master` branch.

[amazon]: https://github.com/aws-quickstart/quickstart-heptio

