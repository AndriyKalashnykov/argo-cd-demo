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

## Add Kubernetes cluster to Argo CD

```shell
kubectx gke
argocd cluster add $(kubectl config current-context)
kubectx gke2
argocd cluster add $(kubectl config current-context)
argocd cluster list
```

## Build and push demo-app Docker image

```shell
cd ./demo-app
./build-push.sh
```

## Connect to a private Git Repo

```shell
argocd repo add https://github.com/argoproj/argocd-example-apps --username <username> --password <token>
```

### Branching

```shell
git checkout main
git checkout -b dev main
git checkout dev
git push origin dev
...
git checkout dev
git merge main
git push --set-upstream origin dev
```

## Add demo-app to ArgoCD

```shell
argocd app create spring-petclinic-dev --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path ./demo-app --dest-name gke2 --dest-namespace spring-petclinic --revision dev --sync-policy automated
argocd app sync spring-petclinic-dev

argocd app create spring-petclinic-prod --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path ./demo-app --dest-name gke --dest-namespace spring-petclinic --revision main --sync-policy automated
argocd app sync spring-petclinic-prod

argocd app list

argocd app set spring-petclinic-dev --sync-policy automated
argocd app set spring-petclinic-prod --sync-policy automated

kubectl config use-context gke2
kubectl get pod -n spring-petclinic
kubectl config use-context gke
kubectl get pod -n spring-petclinic

argocd app delete spring-petclinic-dev
argocd app delete spring-petclinic-prod

argocd app patch myapplication --patch '{"spec": { "source": { "targetRevision": "master" } }}' --type merge
```

## Uninstall Argo CD

```shell
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.7.8/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get all
```

### Support multiple clusters (destinations) for an Application in Argo CD

* [support multiple clusters](https://github.com/argoproj/argo-cd/issues/1673)
* [Proposal & Proof of Concept: Dynamically Generate Applications for Clusters Based On Label Selectors](https://github.com/argoproj/argo-cd/issues/3403)

### Kustomize dry run

```shell
kustomize build demo-app/kustomize/overlays/dev
kustomize build demo-app/kustomize/overlays/prod
```
git 
### Apply Kustomized templates

```shell
kustomize build demo-app/kustomize/overlays/dev | kubectl apply -f-
kubectl get pods,deploy,replica,svc -n spring-petclinic
```

### Add demo-app to ArgoCD with Kustomize

```shell
argocd app create spring-petclinic-dev-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/dev/ --dest-name gke2 --dest-namespace spring-petclinic --revision kustom --sync-policy automated --auto-prune
argocd app sync spring-petclinic-dev-kustomize

argocd app create spring-petclinic-prod-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/prod --dest-name gke --dest-namespace spring-petclinic --revision kustom --sync-policy automated --auto-prune
argocd app sync spring-petclinic-prod-kustomize

argocd app list

kubectl config use-context gke2
kubectl get pod -n spring-petclinic
kubectl config use-context gke
kubectl get pod -n spring-petclinic

argocd app delete spring-petclinic-dev-kustomize
argocd app delete spring-petclinic-main-kustomize
```
