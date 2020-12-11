#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

argocd app create spring-petclinic-dev-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/dev/ --dest-name gke2 --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app create spring-petclinic-prod-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/prod --dest-name gke --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app list

cd $LAUNCH_DIR