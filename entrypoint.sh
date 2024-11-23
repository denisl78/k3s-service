#!/bin/bash

KUBECONFIG_PORT=${KUBECONFIG_PORT:-18081}
python3 -m http.server -d /etc/rancher/k3s ${KUBECONFIG_PORT} >/dev/null 2>&1 &

if [ "${DOCKER_REGISTRY_HOST}" ];then
cat >> /etc/rancher/k3s/registries.yaml <<-EOF
      - http://${DOCKER_REGISTRY_HOST}:5000
EOF
fi

# Probably we are running as k3s-service docker name
sed -i '/^127.0.0.1/s/$/ k3s-service/' /etc/hosts

# Create PV path based on provide variable
if [ -n "${PV_DATA_FOLDER_PATH}" ];then
	mkdir -p ${PV_DATA_FOLDER_PATH} && chmod -R 777 ${PV_DATA_FOLDER_PATH}
fi 

# for prometheus-node-exporter make shared or slave mount as we run under docker
mount --make-rshared /
# Start k3s server
exec /usr/local/bin/k3s "$@"
