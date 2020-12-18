#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
. $SCRIPT_DIR/set-env.sh

CERT_MANAGER_INSTALLED_NAME=test-cert-manager
CERT_MANAGER_NS=cert-manager
CERT_MANAGER_VERSION=v1.1.0

cd $SCRIPT_PARENT_DIR

# GCP cluster role binding
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $(gcloud config get-value account)

kubectl create ns $CERT_MANAGER_NS || true

# Install Cert Manager
kubectl label namespace $CERT_MANAGER_NS cert-manager.k8s.io/disable-validation=true --overwrite
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.crds.yaml -n $CERT_MANAGER_NS
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.yaml -n $CERT_MANAGER_NS

# Helm
# --------------------------------------------------------------------------------------------------

# helm install $CERT_MANAGER_INSTALLED_NAME jetstack/cert-manager --namespace $CERT_MANAGER_NS --version $CERT_MANAGER_VERSION --set installCRDs=true --set ingressShim.defaultIssuerName=letsencrypt-nginx-prod --set ingressShim.defaultIssuerKind=ClusterIssuer --set ingressShim.defaultIssuerGroup=cert-manager.io

# CertManager v0.12
# kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml --namespace nginx
# helm install cert-manager --namespace nginx --version v0.12.0 jetstack/cert-manager --set ingressShim.defaultIssuerName=letsencrypt --set ingressShim.defaultIssuerKind=ClusterIssuer

# CertManager
# helm repo add jetstack https://charts.jetstack.io
# helm repo update
# kubectl create namespace cert-manager
# kubectl label namespace cert-manager cert-manager.k8s.io/disable-validation=true
# kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.crds.yaml
# helm install cert-manager --namespace cert-manager --version v0.15.1 jetstack/cert-manager
# kubectl apply -f resources/letsencrypt-issuer.yaml

# helm search repo jetstack/cert-manager --versions

# helm repo add jetstack https://charts.jetstack.io
# helm repo update

# helm uninstall $CERT_MANAGER_INSTALLED_NAME

# Uninstall
# kubectl delete customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io
# kubectl delete customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io
# kubectl delete customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io 
# kubectl delete customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io
# kubectl delete customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io
# kubectl delete customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io
# kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.yaml -n $CERT_MANAGER_NS
# kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.crds.yaml -n $CERT_MANAGER_NS

# kubectl delete ns $CERT_MANAGER_NS

kubectl get crd,Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces
kubectl get all -n $CERT_MANAGER_NS


cd $LAUNCH_DIR