# ArgoCD

## Set up cluster

## Deploy ArgoCD to Kubernetes

- create namespace : `kubect create ns argocd`
- deploy manifest : `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
- verify pods `kubectl get pods -n argocd`
- Access ArgoCD by port forwarding the service on port 8080: `kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0`
- to retrieve built in admin user and auto generated password : `kubectl -n argocd get secret argocd-initial-admin-secret`
- `[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(" "))`
- user = admin

## Login via CLI

- download and install `wget https://github.com/argoproj/argo-cd/releases/download/v3.1.8/argocd-linux-amd64-Oargocd`
- `argocd login localhost:8080 --username admin --password <TheAdminPasswordfrombefore> `

## Deploy application to ArgoCD

- create application in Argo CD
- Application name
- Project name
- Auto-create namespace
- Source: reposotory URL
- path: direcory path where YAML is located
- destination section , cluster-url: `https://kubernetes.default.svc/`
- define namespace
- create
- forwward port of the service : `kubectl port-forward svc/argocd-demo-app-service 9090:3000 --address 0.0.0.0`
- access on `http://localhost:9090/` or `curl localhost:9090`