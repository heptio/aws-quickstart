#!/bin/bash -eux

kubernetes_release_tag="v1.5.2"
kubernetes_release_version=${kubernetes_release_tag/v/}

## Install official Kubernetes package

curl --silent "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

apt-get update -q
apt-get upgrade -qy
# Install docker but don't complain that /etc/default/docker has changed
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

## Pre-fetch Kubernetes release image, so that `kubeadm init` is a bit quicker
images=(
  "gcr.io/google_containers/kube-proxy-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/kube-apiserver-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/kube-scheduler-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/kube-controller-manager-amd64:${kubernetes_release_tag}"
  "gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm"
  "gcr.io/google_containers/kube-discovery-amd64:1.0"
  "gcr.io/google_containers/pause-amd64:3.0"
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
