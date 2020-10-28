#!/bin/bash

. ./set-env.sh

kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v$ARGOCD_VER/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get all