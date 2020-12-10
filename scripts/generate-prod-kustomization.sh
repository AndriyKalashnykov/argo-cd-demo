
#!/bin/bash

set -x

LAUNCH_DIR=$(pwd)
SCRIPT_DIR=$(dirname $0)
SCRIPT_PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT_PARENT_DIR_FULL=$(pwd)

cd $SCRIPT_DIR

. ./set-env.sh

cd $SCRIPT_PARENT_DIR_FULL/demo-app/kustomize/overlays/prod

pwd

IMAGE_TAG=1.1

envsubst < kustomization.template.yaml > kustomization.yaml

git commit -am "updated kustomization with IMAGE_TAG=$IMAGE_TAG"
git push

cd $LAUNCH_DIR