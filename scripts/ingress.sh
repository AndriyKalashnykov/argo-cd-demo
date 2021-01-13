#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

# gcloud compute addresses describe argocd-ip --global
gcloud compute addresses list | grep argocd-ip

kubectl get svc -n $NS_NAME
kubectl get ingress argocd-ingress -n $NS_NAME
kubectl describe ingress argocd -n $NS_NAME

cd $LAUNCH_DIR