#!/bin/bash

HOSTNAME="$(hostname -f)"

/bin/cat > /etc/systemd/system/kubelet.service.d/10-hostname.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS= --hostname-override=${HOSTNAME}"
EOF
systemctl daemon-reload
systemctl restart kubelet
