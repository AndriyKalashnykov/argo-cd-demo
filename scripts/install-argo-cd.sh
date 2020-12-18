#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR=$(dirname $0); cd $SCRIPT_DIR; SCRIPT_DIR=$(pwd); cd ..; SCRIPT_PARENT_DIR=$(pwd)
# echo LAUNCH_DIR=$LAUNCH_DIR; echo SCRIPT_DIR=$SCRIPT_DIR; echo SCRIPT_PARENT_DIR=$SCRIPT_PARENT_DIR
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_PARENT_DIR

function get_loadbalancer_ip {
    kubectl get service $SVC_NAME -n $ARGOCD_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
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

# gcloud compute addresses create argocd-ip --global
# gcloud compute addresses describe argocd-ip --global
# gcloud compute addresses create argocd-ip --region us-east1
# gcloud compute addresses describe argocd-ip --region us-east1
# gcloud compute addresses list

kubectl create namespace $ARGOCD_NAME
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VER/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n $ARGOCD_NAME

kubectl get svc $SVC_NAME -n $ARGOCD_NAME -o yaml |sed 's/ClusterIP/LoadBalancer/' | kubectl replace -f -
wait_for_loadbalancer_ip
ARGOCD_IP=$(kubectl get svc $SVC_NAME -n $ARGOCD_NAME  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo -e "waiting for argocd server API to become responsive"
while [ -z "${ARGOCD_HEALTH}" ]; do
    ARGOCD_HEALTH=$(curl -s -k https://${ARGOCD_IP}/api/version | jq '.Version' -r)
    sleep 5
done

# Ingress on GCP
# https://github.com/Luxas98/terraform-gcp-argocd/tree/master/argocd/base/argocd/base

kubectl apply -f k8s/nginx/letsencrypt-issuer-nginx.yaml
kubectl apply -f k8s/nginx/argocd-ingress.yaml -n $ARGOCD_NAME
kubectl get secret argocd-cert-manager-ctls -o yaml -n $ARGOCD_NAME

# kubectl apply -f gcp/k8s/service -n $ARGOCD_NAME
# ARGOCD_IP=$(gcloud compute addresses describe argocd-ip --global --format='value(address)')
# sleep 60

# kubectl patch deployment argocd-server --type json -p='[ { "op": "replace", "path":"/spec/template/spec/containers/0/command","value": ["argocd-server","--staticassets","/shared/app","--insecure"] }]' -n argocd
# kubectl patch deployment argocd-server --patch "$(cat ./gcp/k8s/patch/argocd-server-insecure-patch.yaml)" -n $ARGOCD_NAME
kubectl wait --for=condition=Ready pods --all -n $ARGOCD_NAME

kubectl describe deployment argocd-server -n $ARGOCD_NAME

kubectl get all -n $ARGOCD_NAME

kubectl get ingress -n $ARGOCD_NAME

echo -e "finished installing ArgoCD"

echo -e "ARGOCD_IP=$ARGOCD_IP"
ARGOCD_PWD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=$SVC_NAME -o name | cut -d'/' -f 2)
echo "old ARGOCD_PWD=$ARGOCD_PWD"

#
# update the TLS cert that argocd uses to match the actual domain name
#
# kubectl patch secrets -n $ARGOCD_NAME argocd-cert-manager-ctls -p="{\"data\":{\"tls.crt\": \"${TLS_CERT}\", \"tls.key\":\"${TLS_KEY}\"}}"

argocd login $ARGOCD_IP --insecure --username $ARGOCD_ACCOUNT --password $ARGOCD_PWD 
# --grpc-web
argocd account update-password --insecure --server $ARGOCD_IP --account $ARGOCD_ACCOUNT --current-password $ARGOCD_PWD --new-password $ARGOCD_NEW_PWD

# add current k8s context
argocd cluster add $(kubectl config current-context)

cd $LAUNCH_DIR