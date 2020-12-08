#!/bin/bash

LAUNCH_DIR=$(pwd)
SCRIPT_DIR=$(dirname $0)
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT_PARENT_DIR_FULL=$(pwd)

cd $SCRIPT_DIR

. ./set-env.sh

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v$ARGOCD_VER/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get all

cd $LAUNCH_DIR