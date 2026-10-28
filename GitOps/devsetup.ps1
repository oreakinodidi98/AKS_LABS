gh repo create "app-project-env" --public
Write-Output "setting up a new GitHub repo for the app-project-env"

$env:GITHUB_USERNAME = gh api user --jq .login
Write-Output "retrieving GitHub username and storing in environment variable GITHUB_USERNAME $env:GITHUB_USERNAME"
git clone "https://github.com/$($env:GITHUB_USERNAME)/app-project-env.git"
Microsoft.PowerShell.Management\Set-Location -Path "app-project-env"
Write-Output "cloning the app-project-env repo and changing into the directory"

Write-Output "Step 1/6: Loading shared environment from setup output (.envrc)."

$ENVRC_PATH = "C:\AKS_LABS\GitOps\.envrc"
$env:USER_ASSIGNED_IDENTITY_CLIENT_ID = (Select-String -Path $ENVRC_PATH -Pattern '^export USER_ASSIGNED_IDENTITY_CLIENT_ID=').Line.Split('=')[1]
$env:AZURE_TENANT_ID = (Select-String -Path $ENVRC_PATH -Pattern '^export AZURE_TENANT_ID=').Line.Split('=')[1]
$env:AZURE_SUBSCRIPTION_ID = az account show --query id -o tsv
$env:PRINCIPAL_ID = az ad signed-in-user show --query id -o tsv
Write-Output "Environment loaded: tenant, subscription, identity client ID, principal ID."

Write-Output "Step 2/6: Creating sample directories in app-project-env repo."
New-Item -ItemType Directory -Path "samples/sample-1" -Force | Out-Null
New-Item -ItemType Directory -Path "samples/sample-2" -Force | Out-Null
Write-Output "creating sample directories for sample-1 and sample-2"

Write-Output "Step 3/6: Creating parent Argo CD Application that watches this repo."

$appProjectManifest = Get-Content "C:\AKS_LABS\GitOps\github-app-project-argo-cd-app.yaml" -Raw
$appProjectManifest = $appProjectManifest.Replace('${GITHUB_USERNAME}', $env:GITHUB_USERNAME)
$appProjectManifest | kubectl apply -f -
Write-Output "Create a new Argo CD application in the Management Cluster that watches this GitHub Repository for any changes"

Write-Output "Step 4/6: Creating namespace and applying rendered ASO credentials secret."
kubectl create ns rg-dev-app --dry-run=client -o yaml | kubectl apply -f -
$asoCredentialsManifest = Get-Content "C:\AKS_LABS\GitOps\rg-dev-app-aso-credentials.yaml" -Raw
$asoCredentialsManifest = $asoCredentialsManifest.Replace('${AZURE_SUBSCRIPTION_ID}', $env:AZURE_SUBSCRIPTION_ID)
$asoCredentialsManifest = $asoCredentialsManifest.Replace('${AZURE_TENANT_ID}', $env:AZURE_TENANT_ID)
$asoCredentialsManifest = $asoCredentialsManifest.Replace('${USER_ASSIGNED_IDENTITY_CLIENT_ID}', $env:USER_ASSIGNED_IDENTITY_CLIENT_ID)
$asoCredentialsManifest | kubectl apply -f -
Write-Output "ASO credential secret applied to namespace rg-dev-app."

# Generate a random number
$RAND = Get-Random

# Set it as an environment variable
$env:RAND = $RAND

# Print the random resource identifier
Write-Output "Random resource identifier will be: $RAND"

$env:DEV_CLUSTER_NAME = "dev-cluster-$RAND"
Write-Output "DEV_CLUSTER_NAME set to: $env:DEV_CLUSTER_NAME"

# Set Location
$env:DEV_CLUSTER_LOCATION = "swedencentral"
Write-Output "DEV_CLUSTER_LOCATION set to: $env:DEV_CLUSTER_LOCATION"

$env:CHART_REVISION = "0.4.3"
Write-Output "chart revision set to: $env:CHART_REVISION"

# Get the latest Kubernetes version available in the region
$env:K8S_VERSION=$(az aks get-versions -l $env:DEV_CLUSTER_LOCATION `
--query "values[?isDefault==``true``].version | [0]" `
-o tsv)
Write-Output "Kubernetes version set to: $env:K8S_VERSION"
Write-Output "Step 5/6: Generating Sample 1 AKS Application manifest and pushing to GitHub."

# store resource names in .envrc file
@"
export DEV_CLUSTER_NAME=$env:DEV_CLUSTER_NAME
export DEV_CLUSTER_LOCATION=$env:DEV_CLUSTER_LOCATION
export CHART_REVISION=$env:CHART_REVISION
export K8S_VERSION=$env:K8S_VERSION
"@ | Out-File -FilePath "dev-cluster.envrc" -Encoding utf8
Write-Output "dev-cluster.envrc file created with resource names."

@"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "$env:DEV_CLUSTER_NAME"
  namespace: argocd
spec:
  project: default
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  source:
    repoURL: 'https://mboersma.github.io/cluster-api-charts'
    chart: azure-aks-aso
    targetRevision: v$env:CHART_REVISION
    helm:
      valuesObject:
        clusterName: "$env:DEV_CLUSTER_NAME"
        location: "$env:DEV_CLUSTER_LOCATION"
        subscriptionID: "$env:AZURE_SUBSCRIPTION_ID"
        clientID: "$env:USER_ASSIGNED_IDENTITY_CLIENT_ID"
        tenantID: "$env:AZURE_TENANT_ID"
        authMode: "workloadidentity"
        kubernetesVersion: v$env:K8S_VERSION
        clusterNetwork: "overlay"
        withClusterClass: true
        withClusterTopology: true
        managedMachinePoolSpecs:
          pool0:
            count: 1
            enableAutoScaling: true
            enableEncryptionAtHost: false
            enableFIPS: false
            enableNodePublicIP: false
            enableUltraSSD: false
            maxCount: 3
            minCount: 1
            mode: System
            osSKU: AzureLinux
            vmSize: Standard_DS2_v2
            type: VirtualMachineScaleSets
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: -1
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 10m
"@ | Set-Content -Path "samples/sample-1/aks-argo-application.yaml"

git add .
git commit -m "Sample 1: Create a new AKS cluster as an Argo CD Application"
git push origin main

Write-Output "Step 6/6: Generating Sample 2 ASOv2 manifest and pushing to GitHub."

@"
apiVersion: resources.azure.com/v1api20200601
kind: ResourceGroup
metadata:
  name: rg-dev-app
  namespace: rg-dev-app
  annotations:
    serviceoperator.azure.com/credential-from: rg-dev-app-aso-credentials
spec:
  location: $env:DEV_CLUSTER_LOCATION
---
apiVersion: keyvault.azure.com/v1api20210401preview
kind: Vault
metadata:
  name: app-keyvault-$env:RAND
  namespace: rg-dev-app
  annotations:
    serviceoperator.azure.com/credential-from: rg-dev-app-aso-credentials
spec:
  location: $env:DEV_CLUSTER_LOCATION
  owner:
    name: rg-dev-app
  properties:
    tenantId: $env:AZURE_TENANT_ID
    sku:
      family: "A"
      name: "standard"
    accessPolicies:
      - tenantId: $env:AZURE_TENANT_ID
        objectId: $env:PRINCIPAL_ID  # User or Service Principal Object ID
        permissions:
          secrets:
            - get
            - list
            - set
    enableSoftDelete: true
"@ | Set-Content -Path "samples/sample-2/kv-argo-application.yaml"

git add samples/sample-2/kv-argo-application.yaml
git commit -m "Sample-2: Create new ASOv2 resources"
git push
Write-Output "devsetup complete. Argo CD should now reconcile Sample 1 and Sample 2 from repo path samples/."