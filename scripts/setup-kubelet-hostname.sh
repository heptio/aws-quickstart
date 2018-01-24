#!/bin/bash

HOSTNAME="$(hostname -f)"

/bin/cat > /etc/systemd/system/kubelet.service.d/10-hostname.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS= --hostname-override=${HOSTNAME} --cloud-provider=aws"
EOF
systemctl daemon-reload
