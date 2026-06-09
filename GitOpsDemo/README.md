# AKS + Argo CD GitOps Demo (Beginner Guide)

This folder is a packaged, step-by-step demo for:

- Building an AKS management cluster with Argo CD extension
- Connecting Azure identity to Kubernetes controllers (workload identity)
- Using Git as the source of truth for infrastructure resources
- Watching Argo CD reconcile resources from a GitHub repository

## What this demo shows

By the end, you will see Argo CD manage a multi-app app-of-apps layout from Git:

- `Application` (Sample 1) for an AKS provisioning workflow via Helm/CAPZ
- `ResourceGroup` (Sample 2) via Azure Service Operator (ASO)
- `Vault` (Sample 2) via Azure Service Operator (ASO)
- `Application` (Sample 3) that deploys a demo Kubernetes workload

You will run two scripts in order:

1. `scripts/01-setup.ps1`
1. `scripts/02-devsetup.ps1`

The second script depends on values created by the first script.

## Folder contents

- `scripts/01-setup.ps1`: Builds Azure + AKS base platform and writes `.envrc`
- `scripts/02-devsetup.ps1`: Creates app repo content, applies parent Argo app, pushes sample manifests
- `manifests/github-app-project-argo-cd-app.yaml`: Parent Argo app template
- `manifests/rg-dev-app-aso-credentials.yaml`: ASO credential secret template
- `manifests/identity.yaml`: AzureClusterIdentity manifest
- `manifests/capi-operator-values.yaml`: CAPI operator Helm values

## Prerequisites

Install and sign in first:

- Azure CLI (`az`)
- `kubectl`
- `helm`
- GitHub CLI (`gh`) signed in to your GitHub account
- Git configured with your username/email

Minimum access needed in Azure subscription:

- Permission to create resource groups, AKS, identities, ACR, Key Vault
- Permission to create role assignments

## Step 0: Open terminal in this folder

```powershell
Set-Location C:\AKS_LABS\demo
```

Expected outcome:

- Your prompt shows `C:\AKS_LABS\demo`

## Step 1: Run setup script (build the management platform)

```powershell
./scripts/01-setup.ps1
```

Why:

- Creates the AKS management cluster and supporting Azure resources
- Installs Argo CD extension on AKS
- Writes `.envrc` in this folder with generated values

Expected outputs (highlights):

- `AKS Cluster ... created successfully`
- `ArgoCD extension installed on AKS cluster ...`
- `.envrc file created with resource names at C:\AKS_LABS\demo\.envrc`
- `Next step: run .\scripts\02-devsetup.ps1 ...`

## Step 2: Connect and validate cluster basics

```powershell
kubectl get nodes
kubectl get pods -n argocd
```

Why:

- Verifies Kubernetes API access and Argo components are running

Expected outputs:

- Nodes listed as `Ready`
- Argo pods (for example `argocd-server`, `argocd-repo-server`, `argocd-application-controller`) in `Running`

## Step 3: Install CAPI/CAPZ/ASO prerequisites

```powershell
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true --version v1.15.3
kubectl get pods -n cert-manager

helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update
helm upgrade --install capi-operator capi-operator/cluster-api-operator --create-namespace -n capi-operator-system --wait --timeout=300s -f manifests/capi-operator-values.yaml
kubectl get pods -n azure-infrastructure-system
kubectl -n capi-system get deploy capi-controller-manager -o jsonpath="{.spec.template.spec.containers[0].args}{'\n'}"

kubectl apply -f manifests/identity.yaml
```

Why:

- Sample 1 needs CAPI/CAPZ controllers and CRDs
- Sample 2 needs ASO controller + credentials

Expected outputs:

- `cert-manager` pods running
- `azureserviceoperator-controller-manager` running in `azure-infrastructure-system`
- `capi-controller-manager` args include `ClusterTopology=true`
- `azureclusteridentity.infrastructure.cluster.x-k8s.io/cluster-identity created`

## Step 4: Run dev setup script (Git + sample manifests)

```powershell
./scripts/02-devsetup.ps1
```

Why:

- Creates `app-project-env` repo (or uses existing)
- Applies parent Argo application that watches `samples/` in GitHub
- Renders and applies ASO credential secret with real values
- Generates Sample 1, Sample 2, and Sample 3 manifests and pushes to GitHub

Expected outputs (highlights):

- `Step 1/7` through `Step 7/7`
- `application.argoproj.io/app-project-env-recursive ...`
- Git commit + push output for sample manifests

## Step 5: Verify Argo reconciliation status

```powershell
kubectl get app app-project-env-recursive -n argocd -o wide
kubectl get app app-project-env-recursive -n argocd -o jsonpath="{.status.operationState.phase}{' | '}{.status.operationState.syncResult.revision}{' | '}{.status.sync.status}{' | '}{.status.health.status}{'\n'}{range .status.resources[*]}{.kind}{' '}{.namespace}{'/'}{.name}{' => '}{.status}{'\n'}{end}"
```

Expected output pattern:

- Parent app: `... | Synced | Healthy`
- Child resources:
  - `Application ... => Synced`
  - `ResourceGroup ... => Synced`
  - `Vault ... => Synced`
  - `Application sample-3-platform-workload => Synced`

## Step 6: Drift detection + self-heal (live proof)

Goal:

- Manually change a live Kubernetes object that is managed by Argo CD
- Watch Argo detect drift (`OutOfSync`) and restore the object from Git (`Synced`)

Why this is powerful:

- It proves Git is the source of truth, not manual cluster edits

### 6.1 Pick one child app managed by the parent app

```powershell
$childApp = kubectl get app -n argocd -o jsonpath="{range .items[?(@.metadata.ownerReferences[0].name=='app-project-env-recursive')]}{.metadata.name}{'\n'}{end}" |
  Select-Object -First 1

if (-not $childApp) {
  throw "No child app found under app-project-env-recursive. Check Step 4 and Step 5 first."
}

$originalSelfHeal = kubectl get app $childApp -n argocd -o jsonpath="{.spec.syncPolicy.automated.selfHeal}"
Write-Host "Child app: $childApp"
Write-Host "Original selfHeal: $originalSelfHeal"
```

Expected outcome:

- A child app name is printed
- Original `selfHeal` value is printed (commonly `true`)

### 6.2 Create intentional drift

- Create safe drift on child

```powershell
kubectl edit app $childApp -n argocd

kubectl get app $childApp -n argocd -o jsonpath="{.metadata.name}{' => sync='}{.status.sync.status}{' | health='}{.status.health.status}{' | revision='}{.spec.source.targetRevision}{'\n'}"
```

In the editor:

- Find `spec.syncPolicy.automated.selfHeal`
- Change it to `false`
- Save and exit

Expected outcome:

- App should move to `OutOfSync` after save

### 6.3 Watch Argo self-heal back to Git

- we want to force parent refresh and watch self-heal

```powershell
kubectl annotate app app-project-env-recursive -n argocd argocd.argoproj.io/refresh=hard --overwrite

1..12 | ForEach-Object {
  kubectl get app $childApp -n argocd -o jsonpath="{.metadata.name}{' => sync='}{.status.sync.status}{' | health='}{.status.health.status}{' | selfHeal='}{.spec.syncPolicy.automated.selfHeal}{'\n'}"
  Start-Sleep -Seconds 5
}
```

Expected outcome:

- Status transitions through `OutOfSync`
- Then returns to `Synced` and healthy
- `selfHeal` is reverted back to its original Git value

### 6.4 Final proof check

```powershell
kubectl get app $childApp -n argocd -o jsonpath="{.spec.syncPolicy.automated.selfHeal}{'\n'}"
Write-Host "Expected selfHeal: $originalSelfHeal"
```

Success criteria:

- The current `selfHeal` matches `$originalSelfHeal`
- This confirms Argo discarded manual drift and restored Git-declared state

## Step 7: Multi-app app-of-apps and dependency order proof

Goal:

- Show that one parent app manages multiple child apps
- Show dependency order using sync-wave annotations

Run:

```powershell
kubectl get app -n argocd
kubectl get app sample-3-platform-workload -n argocd -o wide
kubectl get deployment sample-3-web -n sample-3-demo
kubectl get svc sample-3-web -n sample-3-demo
```

Expected outcome:

- Parent app `app-project-env-recursive` is `Synced` and `Healthy`
- Child app `sample-3-platform-workload` exists and becomes `Synced` and `Healthy`
- Workload objects in namespace `sample-3-demo` are created by that child app

Show dependency order (sync-wave):

```powershell
$sample1App = kubectl get app -n argocd -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" | Select-String "^dev-cluster-" | Select-Object -First 1
kubectl get app $sample1App -n argocd -o jsonpath="{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{'\n'}"
kubectl get resourcegroup rg-dev-app -n rg-dev-app -o jsonpath="{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{'\n'}"
kubectl get app sample-3-platform-workload -n argocd -o jsonpath="{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{'\n'}"
```

Expected wave order:

- Sample 1 app wave: `10`
- Sample 2 resources wave: `20` and `21`
- Sample 3 app wave: `30`

Why this is powerful:

- This pattern scales to platform teams managing many teams and environments from one parent app.

## Step 8: Rollback to previous Git commit (incident recovery demo)

Goal:

- Push a bad change
- Watch Argo apply it
- Revert commit in Git and watch Argo restore known-good state

### 8.1 Prepare and capture current state

```powershell
Set-Location C:\Users\oreakinodidi\app-project-env
git log --oneline -n 5
kubectl get app sample-3-platform-workload -n argocd -o wide
```

### 8.2 Push a bad change

```powershell
(Get-Content .\apps\sample-3-workload\workload.yaml) -replace 'nginx:1.27','nginx:not-a-real-tag' | Set-Content .\apps\sample-3-workload\workload.yaml
git add .\apps\sample-3-workload\workload.yaml
git commit -m "Demo failure: break sample-3 image tag"
git push origin main
```

Watch Argo and workload:

```powershell
kubectl get app sample-3-platform-workload -n argocd -w
```

Expected outcome:

- Child app syncs new revision
- Health goes `Degraded` because the Deployment cannot pull image

### 8.3 Roll back with git revert

```powershell
git log --oneline -n 3
git revert --no-edit HEAD
git push origin main
```

Watch recovery:

```powershell
kubectl get app sample-3-platform-workload -n argocd -w
kubectl get pods -n sample-3-demo
```

Expected outcome:

- Argo syncs the revert commit
- App returns to `Healthy`
- Pods return to `Running`

Why this is powerful:

- Recovery is a normal Git operation, not a manual cluster fix.

## Optional: Argo UI access

```powershell
kubectl get secret argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}"
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

- `https://localhost:8080`
- Username: `admin`
- Password: output from first command

## Script handoff summary

- `scripts/01-setup.ps1` writes `demo/.envrc`
- `scripts/02-devsetup.ps1` reads `demo/.envrc`
- `scripts/02-devsetup.ps1` uses `demo/manifests/*.yaml` templates
- Argo CD watches GitHub `app-project-env` repo at `samples/`

## Common issues and quick fixes

1. OutOfSync with `resource name may not be empty`

Cause:

- Sample YAML in repo contains blank values

Fix:

```powershell
Get-Content C:\Users\oreakinodidi\app-project-env\samples\sample-1\aks-argo-application.yaml
Get-Content C:\Users\oreakinodidi\app-project-env\samples\sample-2\kv-argo-application.yaml
./scripts/02-devsetup.ps1
kubectl annotate app app-project-env-recursive -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

1. DNS or API endpoint errors from `kubectl`

Fix:

```powershell
az aks get-credentials -g $env:RG_NAME -n $env:AKS_NAME --overwrite-existing
kubectl get nodes
```

1. ASO resource auth errors (`AuthorizationFailed`)

Cause:

- Managed identity missing role assignment

Fix:

- Re-run `scripts/01-setup.ps1` or assign required role to the user-assigned identity

1. `dev-cluster-*` app is `OutOfSync` but `Healthy`

Cause:

- CAPI controllers are running with `ClusterTopology=false`, so ClusterClass/Cluster topology resources are rejected by webhook

Fix:

```powershell
helm upgrade --install capi-operator capi-operator/cluster-api-operator --create-namespace -n capi-operator-system --wait --timeout=300s -f manifests/capi-operator-values.yaml
kubectl rollout restart deploy/capi-controller-manager -n capi-system
kubectl annotate app app-project-env-recursive -n argocd argocd.argoproj.io/refresh=hard --overwrite
kubectl get app dev-cluster-199624066 -n argocd -w
```

## Demo completion checklist

- [ ] `scripts/01-setup.ps1` completed
- [ ] `scripts/02-devsetup.ps1` completed
- [ ] `kubectl get app app-project-env-recursive -n argocd -o wide` shows `Healthy`
- [ ] Per-resource status shows `Synced` for Sample 1, Sample 2, and Sample 3
- [ ] Rollback demo completed and Sample 3 returned to `Healthy`
