#!/bin/bash

set -x

LAUNCH_DIR=$(pwd)
SCRIPT_DIR=$(dirname $0)
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT_PARENT_DIR_FULL=$(pwd)

cd $SCRIPT_DIR

. ./set-env.sh

argocd app create spring-petclinic-dev-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/dev/ --dest-name gke2 --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app create spring-petclinic-prod-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/prod --dest-name gke --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app list

cd $LAUNCH_DIR