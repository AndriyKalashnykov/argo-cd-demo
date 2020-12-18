#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
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