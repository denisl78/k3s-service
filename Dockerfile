FROM alpine:3.15
ARG K3S_VERSION

### Install k3s ###
RUN apk add --no-cache curl python3 bash
RUN mkdir -p /var/lib/rancher/k3s/agent/images && \
      mkdir -p /var/lib/rancher/k3s/agent/manifests
RUN curl -sfL -o /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s && \
	chmod 755 /usr/local/bin/k3s && \
	ln -s k3s /usr/local/bin/crictl &&  \
	ln -s k3s /usr/local/bin/ctr && \
	ln -s k3s /usr/local/bin/kubectl && \
        echo "PRETTY_NAME=\"K3s ${K3S_VERSION}\"" > /etc/os-release && \
        chmod 1777 /tmp

RUN mkdir -p /var/lib/rancher/k3s/agent/images && \
	curl -L -o /var/lib/rancher/k3s/agent/images/k3s-airgap-images-amd64.tar.zst "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-airgap-images-amd64.tar.zst"

# local registry on :5000
COPY registry-v2.yaml /var/lib/rancher/k3s/server/manifests/

# k3s configuration file
COPY k3s-config.yaml /etc/rancher/k3s/config.yaml

# VOLUMES and ENV's from rancher Dockerfile
VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log

# Expose kube-api
EXPOSE 6443

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
