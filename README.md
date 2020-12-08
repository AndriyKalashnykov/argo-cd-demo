# Argo CD Demo

## Prerequisites

* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [argocd cli](https://argoproj.github.io/argo-cd/cli_installation/)

## Install Argo CD CLI for Mac

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

## Add Kubernetes cluster

```shell
kubectx gke
argocd cluster add $(kubectl config current-context)
kubectx gke2
argocd cluster add $(kubectl config current-context)
argocd cluster list
```

### Kustomize dry run

```shell
kustomize build demo-app/kustomize/overlays/dev
kustomize build demo-app/kustomize/overlays/prod
```

### Apply Kustomized templates

```shell
kustomize build demo-app/kustomize/overlays/dev | kubectl apply -f-
kubectl get pods,deploy,replica,svc -n spring-petclinic-dev
```

### Add demo-app using Kustomize

```shell
argocd app create spring-petclinic-dev-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/dev/ --dest-name gke2 --revision kustom --sync-policy automated --auto-prune

argocd app create spring-petclinic-prod-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/prod --dest-name gke --revision kustom --sync-policy automated --auto-prune

argocd app list

kubectl config use-context gke2
watch kubectl get all -n dev-spring-petclinic
kubectl config use-context gke
watch kubectl get all -n prod-spring-petclinic

argocd app delete spring-petclinic-dev-kustomize
argocd app delete spring-petclinic-main-kustomize
```

## Uninstall Argo CD

```shell
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.7.8/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get all
```
