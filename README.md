# Argo CD Demo

## Prerequisites

* [curl](https://curl.haxx.se/download.html)
* [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/binaries/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [kubectx](https://github.com/ahmetb/kubectx#installation)
* [ArgoCD CLI](https://argoproj.github.io/argo-cd/cli_installation/)

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

### Generate Kustomized templates

```shell
./scripts/generate-dev-kustomization.sh
./scripts/generate-prod-kustomization.sh
```

### Kustomize dry run

```shell
kustomize build demo-app/kustomize/overlays/dev
kustomize build demo-app/kustomize/overlays/prod
```

### Apply Kustomized templates

```shell
kustomize build demo-app/kustomize/overlays/dev | kubectl apply -f-
kubectl get pods,deploy,replica,svc -n dev-spring-petclinic
```

### Add demo-app using Kustomize

```shell
argocd app create spring-petclinic-dev-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/dev/ --dest-name gke2 --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app create spring-petclinic-prod-kustomize --repo https://github.com/AndriyKalashnykov/argo-cd-demo.git --path demo-app/kustomize/overlays/prod --dest-name gke --revision kustom --sync-policy automated --auto-prune --self-heal

argocd app list

kubectl config use-context gke2
watch kubectl get all -n dev-spring-petclinic
kubectl config use-context gke
watch kubectl get all -n prod-spring-petclinic

argocd app delete spring-petclinic-dev-kustomize
argocd app delete spring-petclinic-prod-kustomize
```

## Edit ArgoCD config

```bash
kubectl -n argocd edit cm argocd-cm
```

## Uninstall Argo CD

```shell
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.7.8/manifests/install.yaml
# kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get all
```

### Jenkins pipeline Git push

* [jenkins git push](https://stackoverflow.com/questions/53325544/jenkins-pipeline-git-push)
* [alternative](https://stackoverflow.com/questions/39237910/jenkins-pipeline-cannot-check-code-into-git)

### Patch ArgoCD using ytt

* [Patch ArgoCD using ytt](https://gist.github.com/dnmgns/040e72cdfce299a5b8c1db63004cb059)

```yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:data", "data")
#@ load("@ytt:json", "json")
#@ load("@ytt:base64", "base64")

#! Patch Argo CD Deployment (Deployment/argocd-repo-server) and add ytt
#@overlay/match by=overlay.subset({"kind":"Deployment","metadata":{"name":"argocd-repo-server"}})
---
spec:
  template:
    spec:
      volumes:
      #@overlay/append
      - name: custom-tools
        emptyDir: {}
      #@overlay/match missing_ok=True
      initContainers:
      #@overlay/append
      - name: download-tools
        image: alpine:3.8
        command: [sh, -c]
        args:
        - wget https://github.com/k14s/ytt/releases/download/v0.24.0/ytt-linux-amd64
          && mv ytt-linux-amd64 /custom-tools/ytt && chmod +x /custom-tools/ytt
        volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
      containers:
      #@overlay/match by="name"
      - name: argocd-repo-server
        volumeMounts:
        #@overlay/append
        - mountPath: /usr/local/bin/ytt
          name: custom-tools
          subPath: ytt

# Patch Argo CD ConfigMap (ConfigMap/argocd-cm) and add ytt plugin
#@overlay/match by=overlay.subset({"kind":"ConfigMap","metadata":{"name":"argocd-cm"}})
#@overlay/match-child-defaults missing_ok=True
---
data:
  configManagementPlugins: |
    - name: ytt
      generate:
        command: ["/bin/sh", "-c"]
        args: ["ytt -f . --ignore-unknown-comments=true --data-values-env STR_VAL --data-values-env-yaml YAML_VAL"]
# Patch Argo CD Service (Service/argocd-server) and add metadata labels
#@overlay/match by=overlay.subset({"kind":"Service","metadata":{"name":"argocd-server"}})
#@overlay/match-child-defaults missing_ok=True
---
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: #@ data.values.argocd_hostname
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: '*'
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: #@ data.values.certificate_arn
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
spec:
  type: LoadBalancer

# Patch Argo CD Secret (Secret/argocd-secret) and add username and password:
#@overlay/match by=overlay.subset({"kind":"Secret","metadata":{"name":"argocd-secret"}})
#@overlay/match-child-defaults missing_ok=True
---
  admin.password: #@ base64.encode("{}".format(data.values.argocd_admin_pwd))
  admin.passwordMtime: #@ base64.encode("{}".format(data.values.argocd_admin_pwd_mtime))
```
