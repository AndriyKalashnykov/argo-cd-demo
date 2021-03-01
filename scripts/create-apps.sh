#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

argocd app create spring-petclinic-dev-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/dev/ --dest-name gke2 --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app create spring-petclinic-prod-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/prod --dest-name gke --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app list

cd $LAUNCH_DIR