#!/usr/bin/env bash
# SPDX-License-Identifier: APACHE-2.0
# shellcheck disable=SC1091

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load libraries
. ${SCRIPTPATH}/liblog.sh

set -o errexit
set -o nounset
set -o pipefail
#set -x

CERT_DIR=${CERT_DIR:-$(mktemp -d)}
NAMESPACE=ds
KIND_CLUSTER_NAME=kind

if ! $(kind get clusters -q | grep $KIND_CLUSTER_NAME > /dev/null 2>&1); then
    info "Creating a K8S cluster using Kind"
    kind create cluster --name $KIND_CLUSTER_NAME --config=.bin/kind-conf.yml --image=kindest/node:v1.28.0@sha256:9f3ff58f19dcf1a0611d11e8ac989fdb30a28f40f236f59f0bea31fb956ccf5c
fi

if ! $(kubectl get namespace | grep projectcontour > /dev/null 2>&1); then
    info "Installing Contour ingress controller with Envoy"
    kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
    kubectl patch daemonsets -n projectcontour envoy -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'
    info "waiting for resource deployment to finish..."
    kubectl --namespace projectcontour rollout status deployments
fi

if ! $(kubectl get namespace | grep chaos-mesh > /dev/null 2>&1); then
    info "Installing Chaos Mesh to enable fault simulation within K8S"
    curl -sSL https://mirrors.chaos-mesh.org/v2.6.2/install.sh  | bash -s -- --local kind
    info "waiting for resource deployment to finish..."
    kubectl --namespace chaos-mesh rollout status deployments
fi

if ! $(kubectl get namespace | grep ${NAMESPACE} > /dev/null 2>&1); then
    info "Creating ${NAMESPACE} namespace"
    kubectl create namespace ${NAMESPACE}
fi

if ! $(kubectl --namespace $NAMESPACE get secret custom-cert > /dev/null 2>&1); then
    if [ -f "${CERT_DIR}/tls.crt" ] && [ -f "${CERT_DIR}/tls.key" ] && [ -f "${CERT_DIR}/ca.crt" ]
    then :
    else
	! [ -d "${CERT_DIR}" ] && mkdir -p "${CERT_DIR}"
	# For "customTLS" we need to provide a certificate, so make one now.
	info "Creating TLS certs in ${CERT_DIR}"
	openssl req -x509 -newkey rsa:4096 -nodes -subj '/CN=example.com' -keyout ${CERT_DIR}/tls.key -out ${CERT_DIR}/tls.crt -days 365
	cp ${CERT_DIR}/tls.crt ${CERT_DIR}/ca.crt
    fi

    info "Installing certificate materials into the Kubernets cluster as secrets named 'custom-cert' which we use in the 'myval.yaml' values file."
    kubectl --namespace ${NAMESPACE} create secret generic custom-cert --from-file=${CERT_DIR}/tls.crt --from-file=${CERT_DIR}/tls.key --from-file=${CERT_DIR}/ca.crt
fi

info "Remove any lingering persistent volume claims in the ${NAMESPACE}"
kubectl --namespace ${NAMESPACE} delete pvc --all

if ! $(helm --namespace ${NAMESPACE} list | grep openldap > /dev/null 2>&1); then
    info "Install openldap chart with 'myval.yaml' testing config"
    helm install --namespace ${NAMESPACE} openldap -f .bin/myval.yaml .
    info "waiting for helm deployment to finish..."
    kubectl --namespace ds rollout status sts openldap
fi

info "Fetch the LDAP admin password from k8s"
export LDAP_ADMIN_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} openldap -o jsonpath="{.data.LDAP_ADMIN_PASSWORD}" | base64 --decode; echo)

info "Try to find data in our cluster"
LDAPTLS_REQCERT=never ldapsearch -x -D 'cn=admin,dc=example,dc=org' -w $LDAP_ADMIN_PASSWORD -H ldaps://localhost:30636 -b 'dc=example,dc=org'
