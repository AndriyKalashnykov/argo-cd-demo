#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR/demo-app/kustomize/overlays/dev

envsubst < kustomization.template.yaml > kustomization.yaml

git commit -am "updated kustomization with IMAGE_TAG=$IMAGE_TAG"
git push

cd $LAUNCH_DIR