#!/bin/bash

set -x

LAUNCH_DIR=$(pwd)
SCRIPT_DIR=$(dirname $0)
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT_PARENT_DIR_FULL=$(pwd)

cd $SCRIPT_DIR

. ./set-env.sh

argocd app delete spring-petclinic-dev-kustomize
argocd app delete spring-petclinic-prod-kustomize

cd $LAUNCH_DIR