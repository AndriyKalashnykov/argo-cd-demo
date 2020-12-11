#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

function get_loadbalancer_ip {
    kubectl get service $SVC_NAME -n $NS_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

function wait_for_loadbalancer_ip {
    echo "Waiting up to $WAIT sec for '$SVC_NAME' IP. Each tick is one second."
    set +x
        local time_in_secs=0
        while [[ "$time_in_secs" -lt $WAIT ]]; do
            if [[ "$(get_loadbalancer_ip)" != "" ]] ; then
                return
            fi
            time_in_secs=$(( time_in_secs+1 ))
            sleep 1
            printf "."
        done
        echo "Failed to obtain Service IP after $WAIT sec."
        exit -1
    set -x
}

kubectl create namespace $NS_NAME
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VER/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n $NS_NAME

kubectl get svc $SVC_NAME -n $NS_NAME -o yaml |sed 's/ClusterIP/LoadBalancer/' |kubectl replace -f -
wait_for_loadbalancer_ip
LB_IP=$(kubectl get svc $SVC_NAME -n $NS_NAME  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo -e "\nLB_IP=$LB_IP"

ARGOCD_PWD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=$SVC_NAME -o name | cut -d'/' -f 2)
argocd login $LB_IP --insecure --username $ARGOCD_ACCOUNT --password $ARGOCD_PWD
argocd account update-password --insecure --server $LB_IP --account $ARGOCD_ACCOUNT --current-password $ARGOCD_PWD --new-password $ARGOCD_NEW_PWD

# add current k8s context
argocd cluster add $(kubectl config current-context)

cd $LAUNCH_DIR