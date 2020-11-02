# Argo CD Demo

## Prerequisites

* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [argocd cli](https://argoproj.github.io/argo-cd/cli_installation/)

## Install and set up the ArgoCD CLI

```shell
brew tap argoproj/tap && brew install argoproj/tap/argocd
```

## Install Argo CD

```shell
kubectl create namespace argocd

# Non-HA
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.7.8/manifests/install.yaml
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# HA
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.7.8/manifests/ha/install.yaml

kubectl wait --for=condition=Ready pods --all -n argocd
# watch kubectl get pods -n argocd

kubectl get svc argocd-server -n argocd -o yaml |sed 's/ClusterIP/LoadBalancer/' |kubectl replace -f -
# watch kubectl get svc -n argocd

LB_IP=$(kubectl get svc --namespace argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# or
# kubectl port-forward svc/argocd-server -n argocd 8080:443
# LB_IP=localhost:8080
```

## Change default password for the admin user

Use Argo CD CLI to log in and change default password
```shell
ARGOCD_PWD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)
argocd login $LB_IP --insecure --username admin --password $ARGOCD_PWD
argocd account update-password --insecure --server $LB_IP --account admin --current-password $ARGOCD_PWD --new-password admin
```

or change password directly by patching secret

```shell
# https://www.browserling.com/tools/bcrypt
# bcrypt(admin)=$2a$10$.fPHMWyRDUbMOtTv/7V.UOl.ts5QgRpSVF0aGrkZSMvTInwpgcJ6S

kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$.fPHMWyRDUbMOtTv/7V.UOl.ts5QgRpSVF0aGrkZSMvTInwpgcJ6S",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
```

## Add Kubernetes cluster to Argo CD

```shell
argocd cluster add $(kubectl config current-context)
```

## Build and push demo-app Docker image

```shell
cd ./demo-app
./build-push.sh
```

## Add demo-app to ArgoCD

```shell
kubectl create ns spring-petclinic
argocd app create spring-petclinic --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path ./demo-app --dest-server https://kubernetes.default.svc --dest-namespace spring-petclinic
argocd app create spring-petclinic --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path ./demo-app --dest-server https://35.185.101.202 --dest-namespace spring-petclinic
argocd app sync spring-petclinic
argocd app list
argocd cluster list

argocd app delete spring-petclinic
```

## Uninstall Argo CD

```shell
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.7.8/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get all
```
