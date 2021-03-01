#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

# gcloud compute addresses describe argocd-ip --global
gcloud compute addresses list | grep argocd-ip

kubectl get svc -n $NS_NAME
kubectl get ingress argocd-ingress -n $NS_NAME
kubectl describe ingress argocd -n $NS_NAME

cd $LAUNCH_DIR