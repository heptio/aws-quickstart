#!/bin/bash

# Copyright 2018 by the contributors
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

# Patching kube-proxy to set the hostnameOverride is a workaround for https://github.com/kubernetes/kubeadm/issues/857
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl -n kube-system patch --type json daemonset kube-proxy -p "$(cat <<'EOF'
[
    {
        "op": "add",
        "path": "/spec/template/spec/volumes/0",
        "value": {
            "emptyDir": {},
            "name": "kube-proxy-config"
        }
    },
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/0/volumeMounts/0",
        "value": {
          "mountPath": "/var/lib/kube-proxy",
          "name": "kube-proxy-config"
        }
    },
    {
        "op": "add",
        "path": "/spec/template/spec/initContainers",
        "value": [
            {
                "command": [
                    "sh",
                    "-c",
                    "sed -e \"s/hostnameOverride: \\\"\\\"/hostnameOverride: \\\"${NODE_NAME}\\\"/\" /var/lib/kube-proxy-configmap/config.conf > /var/lib/kube-proxy/config.conf && cp /var/lib/kube-proxy-configmap/kubeconfig.conf /var/lib/kube-proxy/"
                ],
                "env":[
                    {
                        "name": "NODE_NAME",
                        "valueFrom": {
                            "fieldRef": {
                                "apiVersion": "v1",
                                "fieldPath": "spec.nodeName"
                            }
                        }
                    }
                ],
                "image": "busybox",
                "name": "config-processor",
                "volumeMounts": [
                    {
                        "mountPath": "/var/lib/kube-proxy-configmap",
                        "name": "kube-proxy"
                    },
                    {
                        "mountPath": "/var/lib/kube-proxy",
                        "name": "kube-proxy-config"
                    }
                ]
            }
        ]
    }
]
EOF
)"