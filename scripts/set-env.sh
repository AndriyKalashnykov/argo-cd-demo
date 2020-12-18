#!/bin/bash

LATERST_ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

# ./install-argo-cd.sh v1.7.11 

ARGOCD_VER=${1:-$LATERST_ARGOCD_VERSION}
ARGOCD_NAME=${2:-argocd}
SVC_NAME=${3:-argocd-server}
ARGOCD_ACCOUNT=admin
ARGOCD_NEW_PWD=admin

WAIT=120

# echo $LATERST_ARGOCD_VERSION
# echo $ARGOCD_VER