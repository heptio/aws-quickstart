#!/bin/bash

HOSTNAME="$(hostname -f 2>/dev/null || curl http://169.254.169.254/latest/meta-data/local-hostname)"


# Setting --hostname-override is a workaround for https://github.com/kubernetes/kubeadm/issues/653
# Setting --cloud-provider is a workaround for https://github.com/kubernetes/kubeadm/issues/620
# Setting --authentication-token-webhook allows authenticated Prometheus access to the Kubelet metrics endpoint
# (see https://github.com/coreos/prometheus-operator/blob/master/contrib/kube-prometheus/docs/kube-prometheus-on-kubeadm.md)
/bin/cat > /etc/systemd/system/kubelet.service.d/10-hostname.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS= --hostname-override=${HOSTNAME} --cloud-provider=aws --authentication-token-webhook=true"
EOF
systemctl daemon-reload
