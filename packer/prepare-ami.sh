#!/bin/bash -eux
# Copyright 2017 by the contributors
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.


kubernetes_release_tag="v1.5.2"
kubernetes_release_version=${kubernetes_release_tag/v/}

## Install official Kubernetes package

curl --silent "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

# Preconfigure kubelet's systemd config to enable --cloud-provider=aws
mkdir -p /etc/systemd/system/kubelet.service.d/
cat <<EOF > /etc/systemd/system/kubelet.service.d/20-cloud-provider.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=aws"
EOF

## TODO: Update docker to use overlay2 by default 
apt-get update -q
apt-get upgrade -qy
apt-get install -qy \
    docker.io \
    "kubelet=${kubernetes_release_version}-00" \
    "kubeadm=1.6.0-alpha.0-2074-a092d8e0f95f52-00" \
    "kubectl=${kubernetes_release_version}-00" \
    "kubernetes-cni=0.3.0.1-07a8a2-00"

## Also install `jq` and `pip`
apt-get install -qy jq python-pip python-setuptools

## We will need AWS tools as well
pip install "https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz"
pip install awscli

## Pre-fetch various images, so that `kubeadm init` is a bit quicker
## TODO: pre-fetch add-ons that are layed down by kubeadm. 
## Also, address logging and metrics
images=(
  "gcr.io/google_containers/kube-proxy-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/kube-apiserver-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/kube-scheduler-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/kube-controller-manager-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm"
  "gcr.io/google_containers/kube-discovery-amd64:1.0"
  "gcr.io/google_containers/pause-amd64:3.0"
  "gcr.io/google_containers/etcd:2.2.1"
  "quay.io/calico/node:v1.0.2"
  "calico/cni:v1.5.6"
  "calico/kube-policy-controller:v0.5.2"
  "calico/ctl:v1.0.2"
  "weaveworks/weave-kube:1.9.2"
  "weaveworks/weave-npc:1.9.2"
)

for i in "${images[@]}" ; do docker pull "${i}" ; done

## Save release version, so that we can call `kubeadm init --use-kubernetes-version="$(cat /etc/kubernetes_community_ami_version)` and ensure we get the same version
echo "${kubernetes_release_tag}" > /etc/kubernetes_community_ami_version

## Cleanup packer SSH key and machine ID generated for this boot

rm /root/.ssh/authorized_keys
rm /home/ubuntu/.ssh/authorized_keys
rm /etc/machine-id
touch /etc/machine-id

## Done!
