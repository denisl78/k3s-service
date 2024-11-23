# k3s-service

## Info
* Using k3d related images
* Airgap build, no images pull related to k3s
* Contains docker registry with image, can be used without external

## Build
* Predefined variables
```
# https://github.com/k3s-io/k3s/releases
export K3S_NAME=k3s-service
export K3S_VERSION=v1.30.6+k3s1
export K3S_IMAGE="${K3S_NAME}:${K3S_VERSION//+/-}"
export K3S_SERVICE_PORT=18081 # using to expose kubeconfig file
```
* Build k3s docker image
```
docker build --rm \
    --build-arg K3S_VERSION \
    -t ${K3S_IMAGE} .
```

## Run
* Start k3s localy
```
docker run -d -p 6443:6443 -p 18081:18081 -p 5000:5000 \
    -e DOCKER_REGISTRY_HOST \
    --tmpfs /run --tmpfs /var/run \
    --privileged \
    --shm-size=2g \
    --name ${K3S_NAME} ${K3S_IMAGE}
```
* Get k3s ip address
```
K3S_SERVICE_HOST=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${K3S_NAME})
```
* Import kubeconfig from k3s
```
while [ "$(curl -s -o /dev/null -w ''%{http_code}'' http://${K3S_SERVICE_HOST}:${K3S_SERVICE_PORT}/k3s.yaml)" != "200" ];do sleep 3;done
curl ${K3S_SERVICE_HOST}:${K3S_SERVICE_PORT}/k3s.yaml -o kubeconfig
export KUBECONFIG=./kubeconfig
```

## Using k3s
* Get some docker image
```
docker pull alpine:3.15
```
* Upload docker image to local k3s registry using `skopeo`
```
skopeo copy --dest-no-creds --dest-tls-verify=false \
                docker-daemon:alpine:3.15 \
                docker://${K3S_SERVICE_HOST}:5000/alpine:3.15
```
* Deploy simple pod, with image on k3s registry
```
echo 'apiVersion: v1
kind: Pod
metadata:
  name: alpine
spec:
  containers:
  - name: alpine
    image: localhost:5000/alpine:3.15' | kubectl apply -f -
```
* output
```
$ kubectl get pods
NAME     READY   STATUS      RESTARTS     AGE
alpine   0/1     Completed   1 (2s ago)   4m49s
```
