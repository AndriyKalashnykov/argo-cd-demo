#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

argocd app delete spring-petclinic-dev-kustomize
argocd app delete spring-petclinic-prod-kustomize

cd $LAUNCH_DIR