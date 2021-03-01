#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VER/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl delete -f k8s/nginx/argocd-ingress.yaml -n $ARGOCD_NAME
# kubectl delete secret argocd-cert-manager-ctls -n $ARGOCD_NAME

kubectl delete -f gcp/k8s/service -n $ARGOCD_NAME

kubectl delete -f k8s/nginx/letsencrypt-issuer-nginx.yaml

# gcloud compute addresses delete argocd-ip --global --quiet
# gcloud compute addresses delete argocd-ip --region us-east1  --quiet

kubectl -n $ARGOCD_NAME get all

cd $LAUNCH_DIR