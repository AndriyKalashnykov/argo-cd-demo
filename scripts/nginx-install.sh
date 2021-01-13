#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
. $SCRIPT_DIR/set-env.sh

NGINX_INSTALLED_NAME=test-nginx-ingress
NGINX_NS=ingress-nginx
NGINX_VER=v0.41.2

cd $SCRIPT_PARENT_DIR

# Docs
# https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx

kubectl create ns $NGINX_NS || true

# GCP cluster role binding
ACCOUNT=$(gcloud info --format='value(config.account)')
kubectl create clusterrolebinding owner-cluster-admin-binding --clusterrole cluster-admin --user $ACCOUNT

# Install Nginx controller
# https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md

# kubectl apply -f https://github.com/kubernetes/ingress-nginx/blob/master/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${NGINX_VER}/deploy/static/provider/cloud/deploy.yaml
kubectl wait -n $NGINX_NS --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# Get the version of Nginx controller
POD_NAME=$(kubectl get pods -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}' -n $NGINX_NS)
kubectl exec -it $POD_NAME -n $NGINX_NS -- /nginx-ingress-controller --version

kubectl -n $NGINX_NS get all -l app.kubernetes.io/name=ingress-nginx 
kubectl -n $NGINX_NS get services -o wide
kubectl -n $NGINX_NS get svc -o wide

# Uninstall
# kubectl delete -f https://github.com/kubernetes/ingress-nginx/blob/master/deploy/static/provider/cloud/deploy.yaml
# kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${NGINX_VER}/deploy/static/provider/cloud/deploy.yaml
# kubectl delete -f
# https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-${NGINX_VER}/deploy/static/mandatory.yaml
kubectl delete -A ValidatingWebhookConfiguration test-nginx-ingress-ingress-nginx-admission
# kubectl get -A ValidatingWebhookConfiguration

# Helm --------------------------------------------------------------------------------------------------

# Helm install
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update

# helm install $NGINX_INSTALLED_NAME ingress-nginx/ingress-nginx --namespace $NGINX_NS --version 3.15.2
# # --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true

# Older nginx version
# helm search repo stable/nginx-ingress --versions
# helm install $NGINX_INSTALLED_NAME stable/nginx-ingress --version 1.41.3  

# Newer nginx version
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm search repo ingress-nginx --versions

# helm show values ingress-nginx/ingress-nginx --version 3.15.2

# Upgrade Help chart
# helm upgrade --values=ghost-values.yaml $NGINX_INSTALLED_NAME ingress-nginx/ingress-nginx
# helm upgrade $NGINX_INSTALLED_NAME ingress-nginx/ingress-nginx --reuse-values --version 3.15.10

# Uninstall Helm chart
# helm uninstall $NGINX_INSTALLED_NAME --keep-history
# helm list --uninstalled

kubectl get all -n $NS_NAME

cd $LAUNCH_DIR