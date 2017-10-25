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

SOURCE_DIR="$(cd "$(dirname "$0")"; pwd)"
KUBERNETES_RELEASE="v1.7.6"
CNI_RELEASE="0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff"

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main" > /etc/apt/sources.list.d/docker.list

export DEBIAN_FRONTEND=noninteractive
## Make sure we get the latest updates since the base image was released
apt-get update -q
apt-get upgrade -qy

## TODO: Update docker to use overlay2 by default
apt-get install -qy \
    docker-engine=1.12.6-0~ubuntu-xenial \
    jq \
    python-pip \
    python-setuptools \
    ebtables \
    socat \
    ntp

apt-mark hold docker-engine

## Install official Kubernetes binaries
mkdir -p /tmp/kubebin
(
  cd /tmp/kubebin
  curl -sf -O "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/amd64/kubelet"
  curl -sf -O "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/amd64/kubectl"
  curl -sf -O "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/amd64/kubeadm"
  curl -sf -O "https://storage.googleapis.com/kubernetes-release/network-plugins/cni-amd64-${CNI_RELEASE}.tar.gz"

  install -o root -g root -m 0755 ./kubeadm /usr/bin/kubeadm
  install -o root -g root -m 0755 ./kubectl /usr/bin/kubectl
  install -o root -g root -m 0755 ./kubelet /usr/bin/kubelet

  # Also install CNI
  mkdir -p /opt/cni
  (
    cd /opt/cni
    tar -xzf "/tmp/kubebin/cni-amd64-${CNI_RELEASE}.tar.gz"
  )
)
rm -rf /tmp/kubebin

## Install systemd scripts for kubelet
sudo mkdir -p /etc/systemd/system/kubelet.service.d
install -o root -g root -m 0600 "${SOURCE_DIR}/systemd/kubelet.service" \
  /etc/systemd/system/kubelet.service
install -o root -g root -m 0600 "${SOURCE_DIR}/systemd/10-kubeadm.conf" \
  /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
install -o root -g root -m 0600 "${SOURCE_DIR}/systemd/20-cloud-provider.conf" \
  /etc/systemd/system/kubelet.service.d/20-cloud-provider.conf

systemctl daemon-reload
systemctl enable kubelet

## We will need AWS tools as well
pip install "https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz"
pip install awscli

## Pre-fetch various images, so that `kubeadm init` is a bit quicker
images=(
  "gcr.io/google_containers/etcd-amd64:3.1.10"
  "gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.4"
  "gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4"
  "gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4"
  "gcr.io/google_containers/kube-apiserver-amd64:${KUBERNETES_RELEASE}"
  "gcr.io/google_containers/kube-controller-manager-amd64:${KUBERNETES_RELEASE}"
  "gcr.io/google_containers/kube-proxy-amd64:${KUBERNETES_RELEASE}"
  "gcr.io/google_containers/kube-scheduler-amd64:${KUBERNETES_RELEASE}"
  "gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3"
  "gcr.io/google_containers/pause-amd64:3.0"
  "quay.io/calico/cni:v1.11.0"
  "quay.io/calico/kube-controllers:v1.0.0"
  "quay.io/calico/node:v2.6.2"
  "weaveworks/weave-kube:2.0.4"
  "weaveworks/weave-npc:2.0.4"
)

for i in "${images[@]}" ; do docker pull "${i}" ; done

## Save release version, so that we can call `kubeadm init --use-kubernetes-version="$(cat /etc/kubernetes_community_ami_version)` and ensure we get the same version
echo "${KUBERNETES_RELEASE}" > /etc/kubernetes_community_ami_version

## Cleanup packer SSH key and machine ID generated for this boot
rm /root/.ssh/authorized_keys
rm /home/ubuntu/.ssh/authorized_keys
rm /etc/machine-id
touch /etc/machine-id

## Done!
