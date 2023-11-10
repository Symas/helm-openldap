#!/usr/bin/env bash
# SPDX-License-Identifier: APACHE-2.0
# shellcheck disable=SC1091

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load libraries
. "${SCRIPTPATH}"/liblog.sh

set -o errexit
set -o nounset
set -o pipefail
#set -x

CERT_DIR=${CERT_DIR:-$(mktemp -d)}
NAMESPACE=ds
KIND_CLUSTER_NAME=kind


if ! kind get clusters -q | grep -q $KIND_CLUSTER_NAME; then

    # 1. Create a Docker registry container unless it already exists
    reg_name='kind-registry'
    reg_port='5001'
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
	info "Starting Docker registry on localhost:${reg_port}"
	docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" registry:2
    fi

    # 2. Create kind cluster with containerd registry config dir enabled
    # TODO: kind will eventually enable this by default and this patch will
    # be unnecessary.
    #
    # See:
    # https://github.com/kubernetes-sigs/kind/issues/2875
    # https://github.com/containerd/containerd/blob/main/docs/cri/config.md#registry-configuration
    # See: https://github.com/containerd/containerd/blob/main/docs/hosts.md
    info "Creating a Kind/Kubernetes cluster"
    cat <<EOF | kind create cluster --name $KIND_CLUSTER_NAME --image=kindest/node:v1.28.0@sha256:9f3ff58f19dcf1a0611d11e8ac989fdb30a28f40f236f59f0bea31fb956ccf5c --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
  - containerPort: 30636
    hostPort: 30636
  - containerPort: 30389
    hostPort: 30389
- role: worker
- role: worker
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
EOF

    # 3. Add the registry config to the nodes
    #
    # This is necessary because localhost resolves to loopback addresses that are
    # network-namespace local.
    # In other words: localhost in the container is not localhost on the host.
    #
    # We want a consistent name that works from both ends, so we tell containerd
    # to alias localhost:${reg_port} to the registry container when pulling
    # images.
    REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
    info "Add the registry config to the nodes..."
    for node in $(kind get nodes); do
	info "\t${node}"
	docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
	cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
	[host."http://${reg_name}:5000"]
EOF
    done

    # 4. Connect the registry to the cluster network if not already connected
    # This allows kind to bootstrap the network but ensures they're on the same
    # network.
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
	info "Connect the registry to the cluster network using Docker networking"
	docker network connect "kind" "${reg_name}"
    fi

    # 5. Document the local registry
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    info "Document the local registry in Kubernetes"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

    info "To use the local registry:"
    cat <<EOF
1. tag it properly, either
   docker tag gcr.io/google-samples/hello-app:1.0 localhost:5001/hello-app:latest
   docker buildx build --push ... -t localhost:5001/hello-app:latest
2. Push it to the local registry
   docker push localhost:5001/hello-app:1.0
3. Use the image
   kubectl create deployment hello-server --image=localhost:5001/hello-app:latest
EOF

fi

if ! kubectl get namespace | grep -q projectcontour; then
    info "Installing Contour ingress controller with Envoy"
    # https://tanzu.vmware.com/developer/guides/service-routing-contour-refarch/
    kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
    # https://kind.sigs.k8s.io/docs/user/ingress/
    kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"},{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'
    info "waiting for resource deployment to finish..."
    kubectl --namespace projectcontour rollout status deployments
fi

if ! kubectl get namespace | grep -q chaos-mesh; then
    info "Installing Chaos Mesh to enable fault simulation within K8S"
    curl -sSL https://mirrors.chaos-mesh.org/v2.6.2/install.sh  | bash -s -- --local kind
    info "waiting for resource deployment to finish..."
    kubectl --namespace chaos-mesh rollout status deployments
fi

if kubectl get namespace | grep -q "${NAMESPACE}"; then
    info "Remove any lingering persistent volume claims in the ${NAMESPACE}"
    kubectl --namespace ${NAMESPACE} delete pvc --all
    if helm list --namespace ds --no-headers --short | grep -q openldap; then
        info "Uninstall previous deployment of OpenLDAP chart"
        helm -n ds uninstall openldap
    fi
    info "Removing namespace ${NAMESPACE}"
    kubectl delete namespace ${NAMESPACE}
fi
info "Creating ${NAMESPACE} namespace"
kubectl create namespace ${NAMESPACE}

#kubectl delete jobs --all-namespaces --field-selector status.successful=1

if ! kubectl --namespace $NAMESPACE get secret custom-cert > /dev/null 2>&1; then
    if [ -f "${CERT_DIR}/tls.crt" ] && [ -f "${CERT_DIR}/tls.key" ] && [ -f "${CERT_DIR}/ca.crt" ]
    then :
    else
        ! [ -d "${CERT_DIR}" ] && mkdir -p "${CERT_DIR}"
        # For "customTLS" we need to provide a certificate, so make one now.
        info "Creating TLS certs in ${CERT_DIR}"
        openssl req -x509 -newkey rsa:4096 -nodes -subj '/CN=example.com' -keyout "${CERT_DIR}"/tls.key -out "${CERT_DIR}"/tls.crt -days 365 > /dev/null 2>&1
        cp "${CERT_DIR}"/tls.crt "${CERT_DIR}"/ca.crt
    fi

    info "Installing certificate materials into the Kubernets cluster as secrets named 'custom-cert' which we use in the 'myval.yaml' values file."
    kubectl --namespace "${NAMESPACE}" create secret generic custom-cert --from-file="${CERT_DIR}"/tls.crt --from-file="${CERT_DIR}"/tls.key --from-file="${CERT_DIR}"/ca.crt
fi

if ! helm --namespace "${NAMESPACE}" list | grep -q openldap; then
    info "Install openldap chart with 'myval.yaml' testing config"
    helm install --namespace "${NAMESPACE}" openldap -f .bin/myval.yaml .
    info "waiting for helm deployment to finish..."
    # kubectl --namespace ds get events --watch &
    # ( kubectl --namespace ${NAMESPACE} wait --for=condition=Ready --timeout=30s pod/openldap-0 || \
    #   kubectl --namespace ${NAMESPACE} logs -l app.kubernetes.io/name=openldap --all-containers=true --timestamps=true --prefix=true --tail=-1 --ignore-errors --follow ) &
    kubectl --namespace "${NAMESPACE}" rollout status sts openldap
fi

# NOTES:
# * https://kind.sigs.k8s.io/docs/user/local-registry/
