#!/bin/bash

ARGOCD_VER=1.7.8
NS_NAME=${1:-argocd}
SVC_NAME=${2:-argocd-server}
ARGOCD_ACCOUNT=admin
ARGOCD_NEW_PWD=admin

WAIT=120