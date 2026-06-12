# Creating Scalable and Resilient Systems

## The Platform Engineering Journey

Platform engineering evolves as DevOps practices mature over time. It is built on top of DevOps and focuses on improving how development teams build, ship, and operate software.

### Key Challenges

- Be agile
- Get teams onboarded and started quickly
- Accelerate time to market
- Support different technology stacks
- Reduce tribal knowledge risk when people leave or move teams
- Maintain consistent standards across teams
- Avoid suboptimal designs that increase:
  - Cost
  - Security and risk exposure
  - Time to business value

## Demo Overview

### Tooling Used and Purpose

- **Cloud-native IaC tool**: enables the lifecycle management of infrastructure resources across any cloud. In this example, we use Crossplane.
- **GitOps tool**: reconciles infrastructure configuration in a repository with the management cluster and ensures the configuration is applied. In this example, we use Argo, but you can use other tools.
- **Management AKS cluster**: required for GitOps and IaC tooling. In this example, we use a generic AKS cluster.
- **Repo**: this is where you host your configurations for:
  - Management cluster configuration: used by Crossplane
  - Infrastructure configurations: deployment definitions
  - Configuration library: reusable configurations available to teams

### High-Level Flow

The demo flow is straightforward: create a private GitHub repo with the three folder areas used by the demo, create the management cluster by running `setup.ps1`, install the Upbound CLI and Crossplane, verify that the cluster is ready, add your configuration to Git, and then connect GitOps and IaC so Argo and Crossplane can reconcile the platform.

If you are on Linux or macOS, run:

```bash
curl -sL "https://cli.upbound.io" | sh
sudo mv up /usr/local/bin/
up version
up uxp install
```

If you are on Windows PowerShell, run:

```powershell
$dest = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Invoke-WebRequest -Uri "https://cli.upbound.io/stable/current/bin/windows_amd64/up.exe" -OutFile "$dest\up.exe"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$dest*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest", "User")
}

$env:Path = "$env:Path;$dest"
up version
up uxp install
```

- `up version` confirms the CLI is installed
- `up uxp install` installs Universal Crossplane into the cluster that your kubeconfig points to

The rest of the detailed walkthrough below covers the exact validation, Git layout, and reconciliation steps.

- Identify the biggest pain points
- Measure and establish a baseline
- Start small and iterate by leveraging assets already in your environment
- Recognize that many customers are currently stitching solutions together

### Example KPI Categories

- **Customer usage**
  - How much value are users getting?
  - Acquisition, retention, engagement, satisfaction, feature usage
- **Pipeline throughput**
  - How efficient is the DevOps process?
  - Time to build, test, deploy, and improve
  - Failed and flaky automation rates
- **Live-site health**
  - How quickly can issues be detected and fixed?
  - Time to detect, communicate, and mitigate
  - Customer impact and support metrics
  - Incident prevention items
  - Aging live-site problems
  - SLA by customer
- **Employee health**
  - How are employees doing?
  - Burnout, vacation time, and employee concern surveys

Meet developers where they are and provide the right information so the platform can drive automation effectively.

## Common Goals for Platform Engineering Practices

- Enable self-service
- Provide guardrails in a secure and governed way
- Facilitate rapid development and onboarding
- Treat infrastructure as self-service
- Manage and control cost

## Shift to a Product Mentality

## Abstracting Complexity

- Enabling a development team to self-service infrastructure and tools is a good starting point
- Providing a fully preconfigured app hosting environment that enables immediate development is even better
- This allows teams to start producing results faster, improving time to value and reducing cognitive overload
- The demos focus on how a development lead can obtain an application hosting environment for a stateful service app
  - The environment includes Azure resources, cloud-native applications, and an AKS cluster where workloads can authenticate with a secret store and retrieve the connection string required to run the application
  - This can all be done with minimal required knowledge from the developer

### Demo 1: Development Lead Self-Service Environment (Terraform + GitHub Actions)

1. A development lead opens a self-service catalog and selects an application template (deploys resources and uses an existing cluster)
2. A pull request is raised in the project repository, which starts automation
3. An AKS cluster already exists (preconfigured and managed by the platform team)
4. Azure Policy handles observability, security, and compliance
5. GitHub Actions and Terraform deploy resources to Azure (database, secret store, identity, ACR)
6. The platform engineering team has already configured the cluster with the Key Vault provider CSI driver
7. Terraform continues deployment by creating a user-assigned identity and federating it for workload identity and Secret Store CSI driver secret injection into pods
8. The pipeline emits parameters needed to deploy the application

### Demo 2: Cloud-Native Approach

- This is the cloud-native approach to Demo 1
- Why this approach:
  - Demo 1 works well, but this model improves self-service using Azure-oriented abstractions, reusable modules, policy alignment, and Kubernetes-native state tracking
  - Terraform primarily detects and reacts to state changes from its own state model, while this approach keeps reconciliation inside the Kubernetes control plane
- Uses open-source tools: Crossplane and Argo
- **BACK stack**: Backstage, Argo, Crossplane, Kratix
- Key difference: a management cluster hosts Argo and Crossplane

#### Crossplane

- A cloud-native infrastructure-as-code tool
- Represents infrastructure resources as Kubernetes resources
- Uses the Kubernetes control plane as the infrastructure lifecycle management plane for cloud infrastructure
- Enables RBAC on individual infrastructure resources
- Must be deployed on the management cluster

#### Argo CD

- A GitOps continuous delivery tool
- Reconciles to a single source of truth
- Reconciles infrastructure or application configuration in a repository with the Kubernetes cluster
  - Argo CD checks what your config files in Git say your app or infrastructure should look like, compares that to what is actually running in Kubernetes, and fixes differences so the cluster matches the repo
- Git is the source of truth, and Argo keeps the cluster aligned with it
- **Benefits** of GitOps include scale, configuration portability, drift detection, automation, auditing, and approvals
- A key difference between GitOps and other CD pipelines (for example Jenkins, GitHub Actions, and Azure DevOps) is the delivery model:
  - Traditional pipelines are usually push-based and run outside the Kubernetes cluster, so they need cluster connectivity details
  - GitOps tools run an in-cluster agent/controller; you add configuration, and the controller pulls from the config repository and applies it

#### Process

1. Argo notices a PR or repo change (in project Repo) and picks up the new desired configuration and starts creating all those resources
2. Crossplane reconciles and provisions/updates cloud resources based on that desired state, while Argo continues to enforce Git as source of truth
3. Crossplane creates another Argo application configuration and deploys it to the shared AKS app cluster (downstream cluster)
4. This app configuration connects to the developer repository, then downloads and installs the configuration

## Enabling Self-Service Through Automation

Self-service through automation is a key aspect of an engineering platform.

### Platform Layers

- **Top layer**
  - Developer identity
  - Orchestration and automation
  - Platform and API catalog
  - Team insights
- **Foundation**
  - Application templates (automation templates)
  - Application platform (opinionated stacks), meaning the platform you actually run on (for example, Kubernetes)
  - Engineering systems that reduce friction (for example, GitHub Actions)

### Azure Deployment Environments

- Self-service infrastructure as code
- Typical use case: a Kubernetes environment where developers are given isolated namespaces

### Example Flow

- Background:
  - The platform engineering team has already created the paved path (shared cluster)
- Developer journey:
  - A developer provisions the infrastructure they need
  - The developer then uses AZD (Azure Developer CLI) to deploy code
  - `azd env list` can be used to view available environments
  - `azd deploy` deploys resources to the AKS cluster in an isolated namespace that reflects resources in the Azure deployment environment

## Copilot Extensibility and Platform Engineering

- How we can take Copilot and apply it to platform engineering
- Use AI to create an Azure deployment environment with the required resources
- Deployment environments can work across tenants
- Enables creation of isolated environments
- Take the tools already used in your environment, make them easy to integrate and extend, and surface them through the tools developers already use, including Copilot
- Simplify what developers need to do through platform engineering and increase developer joy and satisfaction

## Infrastructure as Code

There are multiple IaC options available. One important category is **cloud-native IaC**.

In this model:

- The tooling runs on a Kubernetes management cluster
- Cloud resources are represented as Kubernetes custom resources

### Common Options

- **CAPI (Cluster API)**
  - CAPI has 30+ providers (for example AWS, GCP, and bare metal)
  - It gives you a common framework and language style across providers
  - The Azure provider for Cluster API (**CAPZ**) can deploy both self-managed Kubernetes clusters on Azure and AKS clusters
- **ASO v2 (Azure Service Operator)**
  - Lets you deploy many Azure resources, not just AKS
  - It is now deployed by default and used as a dependency by CAPZ
- **Crossplane**
  - Lets you deploy resources across multiple clouds
  - You can swap it out for any of the above tools based on your needs

### Shared Pattern Across These Tools

All of these tools need a Kubernetes cluster to host them. At a high level, they:

- Install Kubernetes Custom Resource Definitions (CRDs)
- Use an identity to connect to Azure and perform infrastructure actions
- Represent cloud infrastructure as Kubernetes resources and track resource state over time

### Advantages

- **Automation and drift detection**
  - Cloud-native IaC options work well with automation tools such as GitOps
  - This gives you GitOps benefits out of the box, including automated drift detection
  - Kubernetes is strong as a continuous reconciliation loop, compared to non-cloud-native IaC options (such as Terraform) where lock files and state can mean drift is only detected during a redeployment
  - That delay can slow down drift detection and reconciliation of errors
- **Control plane security**
  - With cloud-native tools, deployment control sits in the Kubernetes control plane
  - This lets you limit direct user access to cloud control planes and resources
- **Custom resources**
  - You can create Kubernetes resources that represent multiple infrastructure resources
  - You can also create resources with predefined defaults and only expose the properties teams should change
  - Examples include Composite resources (Crossplane XRDs) and Cluster Classes in CAPI
- **Common tooling across mixed cluster types**
  - You can use the same approach for a self-managed Kubernetes cluster, an AKS cluster, and an AKS cluster connected to a fleet management hub
  - You can also apply associated applications across these cluster types in a consistent way

### Cloud-Native IaC Considerations

- **Kubernetes cluster operations and experience**
  - Ops teams need to grow skills in running and maintaining Kubernetes management clusters
- **Getting started**
  - Ops teams need to learn how to define resources using cloud-native templates
- **Existing investments**
  - This is not saying you should scrap existing investments
  - Start small, and evaluate how technical benefits map to business value
  - You can still deliver self-service using current deployment pipeline tools such as GitHub Actions and Azure DevOps, plus IaC tools such as Terraform, Bicep, and ARM templates

## My Demo

### Tooling used and purpose

Cloud native IaC tool - this tool will enable the LCM of infra resources across any clouds you chose, for this example we are going to show Crossplane.
GitOps - this tool will reconcile the infra configuration in a repositry with the management cluster and ensure the configuration is applied. We will use Argo in the example, but you can use other tools.
Management AKS cluster - this is required for GitOps and IaC tooling, in this example we're going to use a generic AKS cluster.
Repo - this is where you will host your configurations for:
The Management cluster configuratation - this configuration will be used by crossplane.
Infra configurations - configurations of deployments.
Configuration library - configurations available to teams.

### Steps

#### 1. Create a private GitHub repo

Create three folders to keep the demo organized:

- `/mgmtCluster/bootstrap/control-plane/addons`
- `/workloads/team01`
- `/catalog/k8s`

#### 2. Create the management cluster

- Run [setup.ps1](c:/AKS_LABS/Platform%20Engineering/setup.ps1)
- This is the cluster where you install Crossplane and GitOps tooling
- The script creates:
  - A resource group
  - A user-assigned identity for the control plane
  - A user-assigned identity for the kubelet
  - An Azure Container Registry
  - A Log Analytics workspace
  - An Azure Monitor workspace for Prometheus
  - An Application Insights resource
  - A Key Vault with RBAC enabled
  - An AKS cluster with workload identity, OIDC issuer, Azure Monitor, ACNS, and autoscaling enabled
  - Role assignments for the current user, the managed identities, and the AKS Key Vault add-on identity
  - A kubeconfig file named after the AKS cluster
  - A `.envrc` file with the resource names and IDs used later in the demo

#### 3. Install the Upbound CLI and Crossplane

On Windows PowerShell, use this flow:

```powershell
$dest = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Invoke-WebRequest -Uri "https://cli.upbound.io/stable/current/bin/windows_amd64/up.exe" -OutFile "$dest\up.exe"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$dest*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest", "User")
}

$env:Path = "$env:Path;$dest"
up version
up uxp install
```

If you are on Linux or macOS, the equivalent install flow is:

```bash
curl -sL "https://cli.upbound.io" | sh
sudo mv up /usr/local/bin/
up version
up uxp install
```

- `up version` confirms the CLI is installed
- `up uxp install` installs Universal Crossplane into the cluster that your kubeconfig points to
- After install, check the `crossplane-system` namespace, not `upbound-system`

```powershell
kubectl get pods -n crossplane-system
```

- You should see pods such as `crossplane`, `crossplane-rbac-manager`, `crossplane-apollo`, `upbound-controller-manager`, and `webui`
- Apply the Azure provider manifest from [manifests/provider-azure-management.yaml](manifests/provider-azure-management.yaml)

```powershell
kubectl apply -f .\manifests\provider-azure-management.yaml
kubectl get providers.pkg.crossplane.io
kubectl describe provider.pkg.crossplane.io provider-azure-management
```

- Wait until the provider reports `HEALTHY=True` before moving on

- Deploy additional providers when you want to manage more Azure resource types
- Browse providers in Upbound Marketplace: [provider catalog](https://marketplace.upbound.io/providers)
- Example for AKS resources: [provider-azure-containerservice](https://marketplace.upbound.io/providers/upbound/provider-azure-containerservice/v2.5.6)
- Apply the manifest from [manifests/provider-azure-containerservice.yaml](manifests/provider-azure-containerservice.yaml)

```powershell
kubectl apply -f .\manifests\provider-azure-containerservice.yaml
kubectl get providers.pkg.crossplane.io
kubectl describe provider.pkg.crossplane.io provider-azure-containerservice
```

- Keep provider versions pinned in Git and update intentionally after validating a new version in a test environment

- Configure the default Azure `ProviderConfig` so Crossplane can authenticate with the kubelet managed identity

```powershell
$kblAksUaiCliId = $env:KBL_USER_ASSIGNED_IDENTITY_CLIENT_ID
$subscriptionID = (az account show --query id -o tsv)
$tenantID = $env:AZURE_TENANT_ID

@"
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: UserAssignedManagedIdentity
  clientID: $kblAksUaiCliId
  subscriptionID: $subscriptionID
  tenantID: $tenantID
"@ | kubectl apply -f -
```

- Linux/macOS equivalent:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: UserAssignedManagedIdentity
  clientID: $kblAksUaiCliId
  subscriptionID: $subscriptionID
  tenantID: $tenantID
EOF
```

- Validate the ProviderConfig:

```powershell
kubectl get providerconfig.azure.upbound.io
kubectl describe providerconfig.azure.upbound.io default
```

- Validate Crossplane end to end by creating a test Azure resource group from Kubernetes

```powershell
@"
apiVersion: azure.upbound.io/v1beta1
kind: ResourceGroup
metadata:
  name: rg-myfirst
spec:
  forProvider:
    location: West US3
    tags:
      provisioner: crossplane
"@ | kubectl apply -f -
```

- Linux/macOS equivalent:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: azure.upbound.io/v1beta1
kind: ResourceGroup
metadata:
  name: rg-myfirst
spec:
  forProvider:
    location: West US3
    tags:
      provisioner: crossplane
EOF
```

- Check status from Kubernetes:

```powershell
kubectl describe resourcegroup.azure.upbound.io rg-myfirst
```

- Success criteria:
  - Events include `Successfully requested creation of external resource`
  - The resource group exists in your Azure subscription

- Cleanup:

```powershell
kubectl delete resourcegroup.azure.upbound.io rg-myfirst
```

#### 4. Verify the cluster is ready

- Confirm that your kubeconfig points to the management cluster before installing Crossplane providers or writing GitOps configuration
- Use `kubectl get nodes` and `kubectl get pods -A` to confirm the platform components are healthy
- Now we have a configuration that will allow you to create Azure resources using Crossplane and K8s.
- We need to integrate this with a GitOps tool that will allow us to use a GitHub repo as a single source of truth, auto reconcilation, drift detection etc.

Install Argo CD: [getting started guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)

Access Argo CD UI:

```powershell
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get secret argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}"
kubectl port-forward svc/argocd-server -n argocd 8443:443 --address 127.0.0.1
```

Open `https://localhost:8443` and sign in as `admin`.

Connect the Argo CD CLI before creating apps (run this in a separate terminal while port-forward is running):

```powershell
Get-Command argocd
# If missing, install and reopen terminal:
# winget source update
# winget install --id argoproj.argocd --source winget
# argocd version --client
# Get-Command argocd

$argoPassword = kubectl get secret argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}"
argocd login 127.0.0.1:8443 --username admin --password $argoPassword --insecure --grpc-web
argocd app list
```

#### 5. Add your configuration to Git

- Put management cluster bootstrap config in `/mgmtCluster/bootstrap/control-plane/addons`
  - create `crossplane-provider-config.yaml`
  - Go to [Marketplace](https://marketplace.upbound.io/)
  - Find providers wanted and include them in file
- Put workload-specific config in `/workloads/team01`
- Put reusable templates and catalog items in `/catalog/k8s`
- Put downstream infrastructure in `downstreamInfra`

#### 6. Connect GitOps and IaC. Create an Argo App

Use this step to manage Crossplane configuration through an Argo Application instead of applying manifests one by one from a terminal.

Why this matters:

- The first Azure provider gives you a starting point, but real environments need multiple providers and provider configuration over time.
- Keeping provider manifests in Git gives you version history, review approvals, rollback, and a clear source of truth.
- Argo continuously reconciles cluster state to Git, which gives you drift detection and self-healing behavior.

How this fits the overall model:

- Crossplane handles cloud resource lifecycle from Kubernetes custom resources.
- Argo handles desired-state delivery from Git into the management cluster.
- Together they create a pull-based platform workflow instead of manual push-based changes.

How to define Argo Applications:

- Argo CD CLI
- Kubernetes manifests
- Helm charts

In this section we create the initial management-cluster app with Argo CD CLI first. After that, you can add more apps with other methods.

Target end state in the demo:

- Crossplane Configuration: provider and ProviderConfig resources that control Crossplane behavior.
- Downstream Infra: team infrastructure resources such as downstream Kubernetes clusters.
- Team Projects: team application environment configuration and app-level resources.

Create the Argo CD app for your repository:

If your repository is private, register it in Argo CD first:

```powershell
$ghUser = "oreakinodidi98"
$ghRepo = "https://github.com/oreakinodidi98/PlatformEngineeringDemo"
$ghPat = Read-Host "Enter GitHub PAT (repo read access)" -AsSecureString
$ghPatPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ghPat))

argocd repo add $ghRepo --username $ghUser --password $ghPatPlain
argocd repo list
```

Then create the application:

```powershell
argocd app create crossplane-prov-config `
  --repo https://github.com/oreakinodidi98/PlatformEngineeringDemo `
  --path mgmtCluster/bootstrap/control-plane `
  --dest-server https://kubernetes.default.svc `
  --dest-namespace crossplane-prov-config `
  --sync-policy auto
```

If the app already exists, or you created it without auto-sync, run:

```powershell
argocd app set crossplane-prov-config --sync-policy auto
```

Check app status with either the CLI or the UI:

```powershell
argocd app get crossplane-prov-config
```

- UI: `https://localhost:8443`

### 7. Add a Downstream Infrastructure Argo Application

In your private GitHub repo, create the file:

- `mgmtCluster/bootstrap/control-plane/downstreamInfraApp.yaml`

This file defines **two** ArgoCD Applications — one for the test cluster infra, and one for each team's claims folder:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: downstream-infra
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/<GITHUB_USER>/<GITHUB_REPO>
    targetRevision: HEAD
    path: downstreamInfra/testcluster/
  syncPolicy:
    automated: {}
    syncOptions:
      - SkipDryRunOnMissingResource=true
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team01-claims
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/<GITHUB_USER>/<GITHUB_REPO>
    targetRevision: HEAD
    path: downstreamInfra/team01/
  syncPolicy:
    automated: {}
    syncOptions:
      - SkipDryRunOnMissingResource=true
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
```

Notes:

- The finalizer ensures child applications and their resources are deleted when the parent application is deleted.
- Replace `<GITHUB_USER>` and `<GITHUB_REPO>` with your actual values.
- `downstream-infra` watches `downstreamInfra/testcluster/` (manual cluster resources).
- `team01-claims` watches `downstreamInfra/team01/` so that any claim YAML a team pushes there is automatically applied to the management cluster — this is what makes the self-service GitOps flow work. Without it, claims must be applied manually with `kubectl apply`.
- Add a new `teamXX-claims` application for each additional team.

### 8. Add Downstream Infrastructure Resource YAML

Go to `downstreamInfra/testcluster` and add a resource manifest, for example:

```yaml
apiVersion: azure.upbound.io/v1beta1
kind: ResourceGroup
metadata:
  name: rg-myfirst
spec:
  forProvider:
    location: West US3
    tags:
      provisioner: crossplane
```

Commit and push to the `main` branch:

```bash
git add downstreamInfra/testcluster/myfirstcluster.yaml
git commit -m "Create resource group via Crossplane"
git push
```

Validation:

- Verify in Azure that the resource group was created.
- You can add more resource types after confirming the required Crossplane providers are installed.

Key Crossplane guidance:

- Some fields should be set once and then left alone, similar to `ignore_changes` in Terraform.
- This is useful for values such as tags, extensions, and observability settings.
- When migrating from CLI or Terraform, check the Crossplane API docs carefully because parameter names and input shapes can differ.

You can add more resource types by creating additional manifests, as long as the required Crossplane provider is installed. For example:

```yaml
---
apiVersion: containerservice.azure.upbound.io/v1beta1
kind: KubernetesCluster
metadata:
  annotations:
    meta.upbound.io/example-id: containerservice/v1beta1/kubernetesclusterextension
  labels:
    testing.upbound.io/example-name: rg-myfirst
  name: test-clu1-se
spec:
  forProvider:
    apiServerAccessProfile:
      - authorizedIpRanges:
          - 192.168.1.0/24
    defaultNodePool:
      - name: default
        nodeCount: 1
        autoScalingEnabled: true
        maxCount: 5
        minCount: 1
        vmSize: Standard_D2_v2
    dnsPrefix: exampleaks1se
    identity:
      - type: SystemAssigned
    oidcIssuerEnabled: true
    workloadIdentityEnabled: true
    keyVaultSecretsProvider:
      - secretRotationEnabled: true
    location: Sweden Central
    azurePolicyEnabled: true
    resourceGroupNameSelector:
      matchLabels:
        testing.upbound.io/example-name: rg-myfirst
    tags:
      Environment: Test
      Owner: Ore
  writeConnectionSecretToRef:
    name: test-clu1-se-secret
    namespace: crossplane-system
```

For API server authorized IP ranges, use your current public IP instead of a private CIDR.

```powershell
$myIp = (Invoke-RestMethod "https://api.ipify.org?format=json").ip
```

Then set `apiServerAccessProfile.authorizedIpRanges` to `"$myIp/32"` in the cluster manifest.

## Configure the Crossplane-Created Cluster with Argo CD

This section demonstrates the **Remote Management** pattern: Crossplane installs Argo CD on the newly created cluster and configures it to deploy applications from your Git repository.

### Overview

- Crossplane reaches into the AKS cluster it created, installs Argo CD via Helm, and then uses Argo CD to deploy your applications.
- This creates a pull-based GitOps workflow where the downstream cluster continuously reconciles its state with Git.
- Reference: [Deploy Argo CD on AKS](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-argocd)

### Prerequisites

Install the required Crossplane providers in the management cluster:

- **Helm Provider**: [provider-helm](https://marketplace.upbound.io/providers/crossplane-contrib/provider-helm/v1.2.0?tab=managedResources) — to deploy Argo CD via Helm
- **Kubernetes Provider**: [provider-kubernetes](https://marketplace.upbound.io/providers/crossplane-contrib/provider-kubernetes/v1.2.1) — to create resources inside the cluster

Both providers need cluster credentials to function.

### Configure Cluster Access

In the previous step, the AKS cluster wrote its kubeconfig to a secret in the `crossplane-system` namespace. You now need to create two `ProviderConfig` resources—one for Helm and one for Kubernetes—so Crossplane can authenticate with the downstream cluster.

Both providers reference the same kubeconfig secret but serve different purposes:

- **Helm ProviderConfig**: Used by the Helm Release resource to install Argo CD
- **Kubernetes ProviderConfig**: Used by the Kubernetes Object resource to create Argo Application manifests

Create both configurations:

```yaml
---
apiVersion: helm.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: clu1-prov-name-helm
  namespace: crossplane-system
spec:
  credentials:
    source: Secret
    secretRef:
      name: test-clu1-secret
      namespace: crossplane-system
      key: kubeconfig
---
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: clu1-prov-name-k8s
  namespace: crossplane-system
spec:
  credentials:
    source: Secret
    secretRef:
      name: test-clu1-se-secret
      namespace: crossplane-system
      key: kubeconfig
```

### Install Argo CD via Helm

Use Crossplane's Helm provider to deploy Argo CD into the `argocd` namespace:

```yaml
---
apiVersion: helm.crossplane.io/v1beta1
kind: Release
metadata:
  annotations: 
    crossplane.io/external-name: argocd   
  name: clu1-argo  
spec:
  forProvider:
    chart:
      name: argo-cd
      repository: https://argoproj.github.io/argo-helm
      version: 9.5.20
    namespace: argocd   
  providerConfigRef: 
    name: clu1-prov-name-helm
    namespace: crossplane-system
```

### Create an Argo CD Application

Finally, use Crossplane's Kubernetes provider to create an Argo Application resource inside the downstream cluster. This application will watch your Git repository and sync manifests to the cluster.

```yaml
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: core-cluster-configs
spec:
  forProvider:
    manifest:
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: core-cluster-configs
        namespace: argocd
        finalizers:
        - resources-finalizer.argocd.argoproj.io
      spec:
        project: default
        source:    
          repoURL: "https://github.com/oreakinodidi98/PlatformEngineeringDemo" # Use your repo
          targetRevision: HEAD
          path: "workloads/team01"
        syncPolicy:
          automated: {}
        destination:
          namespace: argocd
          server: https://kubernetes.default.svc
  providerConfigRef: 
    name: clu1-prov-name-k8s
    namespace: crossplane-system
```

Notes:

- Replace the `repoURL` with your actual GitHub repository URL.
- The `path` field (`workloads/team01`) points to where you'll store application manifests.
- Argo CD will use `automated` sync policy, meaning it reconciles continuously without manual approval.

## Add Workload Manifests to Git

Before syncing the downstream infrastructure, populate the `workloads/team01` directory with valid Kubernetes manifests. Argo CD will apply these to the downstream cluster.

### Create the Workload Folder Structure

```
workloads/
└── team01/
    ├── namespace.yaml
    └── nginx-deployment.yaml
```

### Example Manifests

**`namespace.yaml`**:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team01-apps
```

**`nginx-deployment.yaml`**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-sample
  namespace: team01-apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### Commit and Push

The Argo Application manifest (created earlier) points to `workloads/team01`, so Argo CD will find and apply these manifests when it syncs.

```bash
git add .
git commit -m "Add Argo CD setup with workload manifests"
git push
```

### Verify Synchronization

Go to the Argo CD UI on your management cluster and sync the `downstream-infra` application.

1. Open the Argo CD UI: `https://localhost:8443`
2. Select the `downstream-infra` application
3. Click **Sync** to trigger reconciliation

Argo CD will then deploy the workload manifests to the downstream cluster.
### Test

In a new terminal, get credentials for the downstream cluster:

```powershell
az aks get-credentials `
  --resource-group rg-myfirst `
  --name test-clu1 `
  --overwrite-existing
```

Check the Helm release status:

```powershell
kubectl -n argocd describe release.helm.crossplane.io clu1-argo
```

Watch the Argo CD Object resource:

```powershell
kubectl -n argocd get object.kubernetes.crossplane.io core-cluster-configs -w
```

Trigger immediate reconciliation of the Helm release:

```powershell
kubectl -n argocd annotate release.helm.crossplane.io clu1-argo crossplane.io/reconcile=now --overwrite
```

Trigger immediate reconciliation of the Kubernetes Object:

```powershell
kubectl -n argocd annotate object.kubernetes.crossplane.io core-cluster-configs crossplane.io/reconcile=now --overwrite
```


### Validate API Access to the Downstream Cluster

If `kubectl` cannot reach the downstream AKS API server, update authorized IP ranges and test access.

1. Get your current public IP:

```powershell
$myIp = (Invoke-RestMethod "https://api.ipify.org?format=json").ip
$myIp
```

2. Allow that IP on the AKS cluster:

```powershell
az aks update `
  --resource-group rg-myfirst `
  --name test-clu1-se `
  --api-server-authorized-ip-ranges "$myIp/32"
```

3. Build and use the downstream kubeconfig from the Crossplane connection secret:

```powershell
kubectl get secret test-clu1-se-secret -n crossplane-system -o jsonpath="{.data.kubeconfig}" > kubeconfig.b64
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Get-Content .\kubeconfig.b64 -Raw))) | Set-Content .\downstream-kubeconfig.yaml
```

4. Test cluster connectivity:

```powershell
$env:KUBECONFIG = "$PWD\downstream-kubeconfig.yaml"
kubectl get ns
```

5. Verify workload deployment in the downstream cluster:

```powershell
kubectl get deployment -A
kubectl get pods -A
kubectl get ns team01-apps
kubectl get deployment nginx-sample -n team01-apps
kubectl get pods -n team01-apps
```

## Recap

You now have a basic automated cloud-native IaC and GitOps workflow that can create and reconcile Azure resources from GitHub, while supporting auditability and approval controls. This is a practical starting point for a self-service platform.

What this demo currently shows:

- A single-team cluster pattern where one Kubernetes cluster can host multiple apps for that team.
- Foundational end-to-end flow: Crossplane-managed Azure resources, downstream cluster provisioning, and Argo CD-based application sync.
- Guardrails that come from Git as the source of truth, including review, history, and repeatable deployment behavior.

Important scope note:

- This is intentionally a minimal baseline, not a full production platform blueprint.
- The sample resources (Resource Group, AKS cluster, Argo app, and starter workload) do not represent a complete developer solution.
- Real platform offerings usually add many more resources, dependencies, policies, and abstractions so developers can provide only a few inputs and get started quickly.

## Stage 10: Deploy Preconfigured, Standardized Solutions in Azure (Demo 2)

In this stage, I stop deploying each resource manually and start exposing a standard platform request that teams can use.

### What This Stage Does

1. Defines a custom API for a standardized AKS deployment using **XRD** (Composite Resource Definition)
2. Connects that API to a **Composition** that creates all required resources
3. Lets a team deploy the full setup by submitting one simple **claim**
4. Validates that all generated resources reconcile successfully

### Key Concepts in Plain Terms

Before diving in, here's what each concept does:

1. **XRD** — Defines the API shape and allowed fields that teams can request
2. **Composition** — Defines what infrastructure and Kubernetes objects get created behind the scenes
3. **XR (Composite Resource)** — The generated composite resource instance created by Crossplane
4. **Claim (XC)** — The user-facing request submitted in a namespace (what teams actually submit)
5. **Patches** — Map claim input values into child resources (enforce standards and enable string concatenation)
6. **Pipeline Mode** — Crossplane v1.13+ feature that uses functions to provision resources

### Overview

This guide walks through setting up a **cloud-native self-service platform** using:
- **Crossplane**: Cloud-native infrastructure provisioning via Pipeline mode
- **ArgoCD**: GitOps-based configuration management  
- **Kubernetes**: Management cluster (hosts Crossplane & Argo) and downstream application clusters

**Result**: One simple claim provisions a complete AKS cluster with ArgoCD pre-installed, ready to deploy applications.

---

### Prerequisites

✅ **Management Cluster Ready**
- `mgmt-aks` running with Crossplane v1.13+ installed
- Helm and Kubernetes providers installed
- Default ProviderConfig configured for Azure

✅ **Providers Installed**
```bash
kubectl get providers.pkg.crossplane.io
# Should show: provider-azure-management, provider-azure-containerservice, 
#              provider-helm, provider-kubernetes
```

✅ **Function Installed**
```bash
kubectl get functions.pkg.crossplane.io function-patch-and-transform
# Should show: HEALTHY=True
```

---

### File Structure

```
mgmtCluster/bootstrap/control-plane/compositions/
├── staging-cluster-definitions.yaml       ✅ XRD (defines the API)
├── function-patch-and-transform.yaml       ✅ Function (enables provisioning)
└── staging-cluster-comp-final.yaml         ✅ Composition (implements resources)

downstreamInfra/team01/
├── team1-apps.yaml                         ✅ Claim (user request)
└── workloads/ (future: app manifests)

.envrc                                       ✅ Environment variables
```

---

### Step-by-Step Deployment

#### Step 1: Install Function

The composition function handles resource provisioning in Pipeline mode.

```bash
kubectl apply -f .\mgmtCluster\bootstrap\control-plane\compositions\function-patch-and-transform.yaml

# Wait for it to become healthy
kubectl get functions.pkg.crossplane.io function-patch-and-transform -w
```

**Status**: Wait until `HEALTHY=True` before proceeding.

#### Step 2: Apply XRD (API Definition)

The XRD defines the interface teams use to request clusters. It's the schema—what parameters are allowed, which are required, and what types they must be.

```bash
kubectl apply -f .\mgmtCluster\bootstrap\control-plane\compositions\staging-cluster-definitions.yaml

# Verify the XRD was applied
kubectl get compositeresourcedefinitions
kubectl describe compositeresourcedefinition staging-aks.compute.example.com
```

**What This Does**: 

The XRD validates that all claims include the required fields and optional fields:
- **Required fields**: `location`, `clustername`, `teamname`
- **Optional fields**: `repourl`, `repopath`

**Practical Use Case**:

An organization with an approved AKS cluster configuration that every team must follow uses the XRD to enforce consistency. The XRD accepts the approved inputs (clustername, location, teamname), and the Composition uses those values to create the AKS cluster and resource group in a controlled, standardized way. This ensures no team can deviate from the platform's standards.

**Why Patches Matter**:

One key thing to notice here is how Crossplane **patches** are used to set values in the composed resources. Values from the XR claim flow into the managed resources, so the platform can enforce approved settings like `clustername` instead of letting teams change them freely. 

For example:
- `clustername: my56cluster` → becomes the actual AKS cluster name
- `location: EU` → gets transformed to the Azure region name `Sweden Central`
- Patches can also concatenate values for secret names, provider configuration names, and other derived values

This allows:
- ✅ Teams provide simple inputs
- ✅ Platform enforces standards and naming conventions
- ✅ No duplicate or conflicting configurations
- ✅ Automatic value transformation (human-friendly to Azure format)

#### Step 3: Apply Composition

The Composition is the implementation layer. It takes the XRD schema and implements the actual resource provisioning logic using **Pipeline mode**.

```bash
kubectl apply -f .\mgmtCluster\bootstrap\control-plane\compositions\staging-cluster-comp-final.yaml

# Verify the composition was applied
kubectl get composition staging-aks
```

**What It Does**: 

When a claim is submitted, Crossplane uses the Composition to automatically create these 6 resources in sequence:
1. **ResourceGroup** in Azure (resource container)
2. **KubernetesCluster** (AKS) in Azure (the actual cluster)
3. **Helm ProviderConfig** (Crossplane authentication to the new cluster)
4. **Argo Helm Release** (installs ArgoCD on the new cluster)
5. **Kubernetes ProviderConfig** (Crossplane Kubernetes authentication)
6. **Argo Application** (configures ArgoCD to watch Git for workloads)

The dependencies are handled automatically: ArgoCD Release waits for the cluster to be Ready before installing, and the Application resource waits for the Helm release to be Ready before syncing workloads.

**Key Implementation Notes for Pipeline Mode:**

Pipeline mode (Crossplane v1.13+) uses **functions** to transform and provision resources. This is how it works:

1. **API Structure**: The composition uses `mode: Pipeline` with a `pipeline` array containing function steps
2. **Function Input**: Resources are provided as input to the `function-patch-and-transform` function under `input.resources:` 
3. **Patch Transformations**: Use `transforms` with `type: map` to translate human-friendly values (e.g., `EU`) into Azure region names (`Sweden Central`)

4. **ProviderConfig readinessChecks — IMPORTANT**:
   - Set to `- type: None` because ProviderConfigs do not become Ready in the normal sense
   - The `secretRef` points to the secret containing the downstream AKS kubeconfig for authentication
   - Crossplane uses that secret to authenticate with the newly provisioned downstream cluster
   - If you leave readiness checks enabled, Crossplane can wait forever or report the resource as not ready even when the configuration is correct
   - Suppressing these checks prevents false "not ready" warnings while the resources function correctly

#### Step 4: Wire the Claims Folder into GitOps

Before teams can submit claims via Git, you need an ArgoCD Application on the management cluster that watches their claims folder. Without this, claims must be applied manually.

Add the `team01-claims` application to `mgmtCluster/bootstrap/control-plane/downstreamInfraApp.yaml` (alongside the existing `downstream-infra` application — see Step 7 above for the full YAML). Then apply it:

```bash
kubectl apply -f .\mgmtCluster\bootstrap\control-plane\downstreamInfraApp.yaml

# Verify both applications exist
kubectl get applications -n argocd
# Expected: downstream-infra, team01-claims, crossplane-prov-config
```

Once `team01-claims` exists, any YAML pushed to `downstreamInfra/team01/` in Git is automatically applied to the management cluster. Teams never need `kubectl` access.

#### Step 5: Submit a Claim

Teams submit a simple request to provision a cluster. This is the **only thing a team needs to do** to get a complete, production-ready cluster.

```bash
kubectl apply -f .\downstreamInfra\team01\team1-apps.yaml
```

Or manually submit a claim YAML:

```yaml
apiVersion: compute.example.com/v1alpha1
kind: staging-aks
metadata:
  name: my56app
spec:
  clustername: my56cluster
  teamname: team01
  location: EU
  repourl: https://github.com/oreakinodidi98/PlatformEngineeringDemo
  repopath: workloads/team01
```

**What This Triggers**: 

Behind the scenes:
1. Crossplane validates inputs against the XRD schema
2. Selects the `staging-aks` Composition
3. Runs the Pipeline mode function with the claim values
4. Provisions all 6 resources in dependency order

**Provisioning Sequence** (automatic):

| Step | Resource | Time | Status |
|------|----------|------|--------|
| 1 | ResourceGroup created | ~10s | READY=True |
| 2 | KubernetesCluster provisioning starts | 5-15m | READY=False (in progress) |
| 3 | ProviderConfigs created | Immediate | (no READY status expected) |
| 4 | Waiting for cluster | 5-15m | Helm Release SYNCED=False (waiting) |
| 5 | Cluster ready | 10-15m | READY=True |
| 6 | ArgoCD installing | 2-5m | Release READY=True |
| 7 | Argo Application syncing | 1-2m | Application READY=True |

---

### Validating Provisioning Progress

After submitting the claim, Crossplane begins provisioning all resources. Here's how to monitor the process and understand what you're seeing.

#### Watch the Claim Status

```bash
kubectl describe staging-aks.compute.example.com/my56app
```

You'll see events and status conditions that tell you the provisioning progress:
- `Synced: False` → Initial state, configuration being applied
- `Synced: True` → Configuration applied successfully
- `Ready: False (Creating)` → Resources being provisioned
- `Ready: True` → All resources ready

#### Monitor Real-Time Claim Changes

```bash
kubectl get staging-aks.compute.example.com/my56app -w
```

Status progression:
```
Synced: False (initial)  →  Synced: True (resources created)
Ready: False (Creating)  →  Ready: True  (all ready)
```

#### Watch the Cluster Being Created in Azure

The KubernetesCluster resource shows the most detailed provisioning information:

```bash
kubectl get kubernetescluster.containerservice.azure.upbound.io/my56cluster -w
```

Status progression (this takes the longest):
```
SYNCED=True, READY=False  (provisioning in Azure - 5-15 min - this is normal!)
   ↓
SYNCED=True, READY=True   (cluster ready, ArgoCD now installing)
```

For detailed information, inspect the resource:

```bash
kubectl describe kubernetescluster.containerservice.azure.upbound.io/my56cluster
```

Look for:
- `.status.conditions[].reason` and `.status.conditions[].message` for error details
- `.status.atProvider` for Azure resource details (region, version, node pool state)
- Events section for reconciliation history

#### View All Provisioned Resources

```bash
kubectl get managed -o wide
```

Expected output during provisioning:
```
NAME                                                    SYNCED    READY    AGE
resourcegroup.azure.upbound.io/my56app-xxxxx           True      True     1m
kubernetescluster.containerservice.azure.upbound.io/my56cluster  True  False  5m
providerconfig.helm.crossplane.io/my56app-xxxxx         True      -       3m
providerconfig.kubernetes.crossplane.io/my56app-xxxxx   True      -       3m
release.helm.crossplane.io/my56app-xxxxx               False     -       2m
object.kubernetes.crossplane.io/my56app-xxxxx          False     -       2m
```

**What each status means**:
- ProviderConfigs: Don't show READY status (expected with `readinessChecks: - type: None`)
- Release/Object: Show `SYNCED=False` while waiting for cluster to be Ready (they depend on it)

---

### Monitoring Provisioning

#### Watch the Claim

```bash
kubectl get staging-aks.compute.example.com/my56app -w
```

Status progression:
```
Synced: False (initial)  →  Synced: True (resources created)
Ready: False (Creating)  →  Ready: True  (all ready)
```

#### Watch the Cluster

```bash
kubectl get kubernetescluster.containerservice.azure.upbound.io/my56cluster -w
```

Status progression:
```
SYNCED=True, READY=False  (provisioning in Azure - 5-15 min)
   ↓
SYNCED=True, READY=True   (cluster ready, ArgoCD installing)
```

#### View All Resources

```bash
kubectl get managed -o wide
```

Expected output:
```
NAME                                                    SYNCED    READY    AGE
resourcegroup.azure.upbound.io/my56app-xxxxx           True      True     1m
kubernetescluster.containerservice.azure.upbound.io/my56cluster  True  False  5m
release.helm.crossplane.io/my56app-xxxxx               False            2m
object.kubernetes.crossplane.io/my56app-xxxxx          False            2m
```

---

### Expected Timeline

| Phase | Duration | What Happens |
|-------|----------|-------------|
| **Claim Submitted** | 0s | Claim validated, composition selected, pipeline starts |
| **ResourceGroup Created** | ~10s | Azure resource group ready |
| **AKS Provisioning Begins** | Immediate | Crossplane sends cluster creation request to Azure |
| **AKS Cluster Provisioning** | 5-15m | ⏳ Azure creates cluster, installs add-ons, scales node pools |
| **Cluster Ready in Azure** | 10-15m | KubernetesCluster resource shows READY=True |
| **ProviderConfigs Created** | Immediate | Crossplane configures Helm and Kubernetes authentication |
| **ArgoCD Installation** | 2-5m | Helm release deploys ArgoCD to the new cluster |
| **Application Sync Begins** | 1-2m | Argo Application starts watching Git repository |
| **✅ Complete** | **15-25 min** | Cluster ready, ArgoCD installed, applications deploying |

**Note**: The longest phase is AKS cluster provisioning (5-15 minutes). This is normal and happens in Azure. During this time, the KubernetesCluster resource will show `SYNCED=True, READY=False`.

---

### Understanding the Architecture

#### Single Repo, Two Zones Pattern

This design keeps infrastructure requests and application workloads organized:

**Management Cluster Zone** (`mgmtCluster/bootstrap/`)
- Hosts Crossplane (infrastructure provisioning engine)
- Hosts ArgoCD (GitOps orchestration engine)
- Contains definitions (XRD, Composition, Functions)
- **Role**: Control plane for infrastructure — the "brain" of your platform

**Workload Zone** (`downstreamInfra/`)
- Contains infrastructure claims (staging-aks requests)
- Contains workload manifests (application configurations)
- **Role**: User-facing place to request infrastructure and deploy apps

**End-to-End Flow**:
1. Team writes a claim in `downstreamInfra/team01/team1-apps.yaml`
2. Claim reaches management cluster via GitOps sync or `kubectl apply`
3. Crossplane detects the new claim, validates it, and starts provisioning
4. AKS cluster is created in Azure
5. Kubeconfig secret is automatically written to the management cluster
6. Crossplane installs ArgoCD on the new cluster using the secret
7. ArgoCD Application is created pointing to `workloads/team01/` in Git
8. ArgoCD watches the Git repository and automatically deploys all workload manifests
9. Team's applications are now running on the new cluster

#### How Patches Customize Resources

The Composition uses **patches** to customize resources from claim values:

Example transformations:
- Claim input `location: EU` → Composition transforms to Azure region `Sweden Central`
- Claim input `clustername: my56cluster` → becomes AKS cluster name `my56cluster`
- Patches concatenate values for derived names: secret names, provider names, etc.

This allows:
- ✅ Teams provide only simple inputs
- ✅ Platform automatically enforces standards
- ✅ No duplicate or conflicting configurations
- ✅ Automatic value transformation (human-friendly to Azure format)
- ✅ Centralized control of naming and resource conventions

---

### Troubleshooting

#### Claim stuck in `Ready=False (Creating)`

**Cause**: AKS cluster still provisioning (normal for first 10-15 minutes)

**Solution**: Wait and monitor
```bash
kubectl describe kubernetescluster.containerservice.azure.upbound.io/my56cluster
```

#### Release/Object showing `SYNCED=False`

**Cause**: Waiting for KubernetesCluster to be `READY=True`

**Solution**: This is expected. Once cluster is ready, these will automatically sync.

#### "ProviderConfig not Ready" warning

**Cause**: ProviderConfigs don't follow standard Ready logic

**Solution**: This is expected. We set `readinessChecks: - type: None` to suppress false warnings. They work correctly even though they don't show as Ready.

#### Schema validation error on composition

**Cause**: Crossplane version mismatch

**Solution**: Ensure Crossplane v1.13+
```bash
kubectl get deployment crossplane -n crossplane-system -o jsonpath='{.spec.template.spec.containers[0].image}'
```

---

### Cleanup

Delete the provisioned infrastructure:

```bash
# Delete the claim - cascades to all composed resources
kubectl delete staging-aks.compute.example.com/my56app

# Verify deletion (AKS deletion takes 5-10 minutes in Azure)
kubectl get managed -w
```

This removes:
- ✓ Azure ResourceGroup
- ✓ AKS Cluster
- ✓ ProviderConfigs
- ✓ ArgoCD Release
- ✓ Argo Application

---

### Next Steps

**Extend the Platform**:
1. Add more providers (databases, storage, networking)
2. Add Gatekeeper policies for resource governance
3. Add team RBAC for namespace isolation
4. Add pre-defined workload templates in the catalog
5. Connect to Backstage for developer portal

**Automate Claims**:
1. Create CI/CD pipeline to generate claims from templates
2. Add approval workflows before claim submission
3. Add cost estimation and quota validation

---

### Key Files Reference

| File | Purpose | Type |
|------|---------|------|
| `staging-cluster-definitions.yaml` | API schema | XRD |
| `function-patch-and-transform.yaml` | Resource provisioning engine | Function |
| `staging-cluster-comp-final.yaml` | Provisioning logic | Composition |
| `team1-apps.yaml` | Infrastructure request | Claim |
| `notes.md` | Full walkthrough | Documentation |

---

### Important Constraints & Notes

⚠️ **Crossplane Version**: v1.13+ required (Pipeline mode)

⚠️ **ProviderConfig readinessChecks**: Must be `- type: None` (they don't become Ready normally)

⚠️ **Kubeconfig Secret**: Created automatically in `crossplane-system` namespace when AKS cluster is provisioned

⚠️ **Azure Credentials**: Management cluster must have Azure permissions via identity or service principal

⚠️ **Cluster Provisioning Time**: AKS clusters take 5-15 minutes to provision in Azure (not instant)

---

### Recap: Standardized Cluster Request Flow

1. **Teams submit a simple claim** - Just 5 parameters (clustername, teamname, location, repo, path)
2. **Crossplane enforces standards** - XRD validates inputs, Composition enforces approved configuration
3. **All complexity centralized** - Platform team controls resource creation in one place
4. **Fully auditable** - All resources tracked in Kubernetes, Git history preserved, easy to replicate

This is a **baseline platform pattern**. A full production solution will include additional policies, dependencies, and app-environment components.

## Links

[Crossplane](https://www.crossplane.io/?_gl=1*1dro6di*_ga*MTY2NDM4MzI0Ni4xNzgxMTY2MzY1*_ga_SFCPQYSLHY*czE3ODExNjYzNjUkbzEkZzAkdDE3ODExNjYzNjUkajYwJGwwJGgw)
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)

## Part 3: Deploy a Cloud Native App with a Full App Environment in Azure

* Examples
  * [Part 1: Create, Configure Mgmt Cluster, Repo, Tools and Deploy Infra](readme.md)
  * [Part 2: Deploy Preconfigured, Standardized Solutions in Azure](readme2.md)
  * Part 3: Deploy a Cloud Native App with a Full App Environment in Azure

A cloud native app is made up of more than just a namespace and an Argo Application. In practice, you usually also need an identity, access to a secret store, a database, and observability.

With that in mind, in this part of the demo we will use Crossplane to deploy an application to an existing AKS cluster:

1. In this demo, we will create a project-specific resource group, deploy all required resources, set up identity permissions as in the previous steps, and store the CosmosDB connection string in Key Vault.
2. Using Crossplane, we will then create another Argo app configuration on the shared app cluster (`my56cluster`). This uses an app-of-apps pattern (one Argo app manages another app configuration). That configuration connects to the developer app repo, which contains the templated Helm chart, and continuously reconciles the environment (keeps the cluster state aligned with what is in Git) by creating an isolated project namespace for the team and deploying a container with workload identity (the app uses an Azure-managed identity instead of hard-coded credentials), so it can connect to Azure Key Vault and retrieve the CosmosDB connection string.

    > Note!
      * In this example we won't create a CosmosDB instance to keep costs down, but you'll still see how the flow works. We'll simulate the pod retrieving the secret by manually creating it in K8s, then using Crossplane to create a secret from it.

## Prerequisites
1. You will need the cluster created in the previous step.
2. You will also need these values ready, and you should update the configuration files with them where noted:
  * Cluster name (the AKS cluster name), for example `my56cluster`
  * Cluster resource group (the Azure resource group that contains the cluster), for example `my56app-kzzj2`
  * Kubelet user-assigned identity resource ID (the full Azure resource ID for the identity you created earlier), for example:
    * `/subscriptions/<subscriptionId>/resourceGroups/<mgmtClusterResGroup>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/kbl-infra002-uai`

### Step 1 : Simulating a Cosmos DB connection string
In this sample, we are not creating a Cosmos DB connection string directly. Instead, we assume you are using a [CosmosDB provider](https://marketplace.upbound.io/providers/upbound/provider-azure-cosmosdb/latest/resources/cosmosdb.azure.upbound.io/Account/v1beta1) (a Crossplane component that creates and manages Cosmos DB resources), and that it has already retrieved the connection string and written it to a Kubernetes secret.

* Add the secret to the management cluster:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: db-conn-string
  namespace: crossplane-system
type: Opaque
stringData:
  db-conn-string: mongodb://mongo-app1-connection-string
EOF
```

PowerShell alternative:

```powershell
@"
apiVersion: v1
kind: Secret
metadata:
  name: db-conn-string
  namespace: crossplane-system
type: Opaque
stringData:
  db-conn-string: mongodb://mongo-app1-connection-string
"@ | kubectl apply -f -
```

### Step 2 : XRD
* Use this file, which defines the XRD (the schema that controls what developers are allowed to provide): `C:\PlatformEngineeringDemo\mgmtCluster\bootstrap\control-plane\compositions\prod-cluster-definitions.yaml`
As defined in that XRD, these are the properties developers can configure and only one that is required is the location:
```yaml
properties:
  spec:
    type: object
    properties:
      appname:
        type: string
      repourl:
        type: string
      repopath:
        type: string
      location:
        type: string
        oneOf:
          - pattern: '^EU$'
          - pattern: '^US$'
    required:
      - location
```

1. appname: the application name.
2. repourl: the Git repository URL, for example 'https://github.com/oreakinodidi98/PlatformEngineeringDemo'.
3. repopath: the path in that repository where the manifests live, for example 'workloads/team01/infra002'.

Add the XRD to the cluster:
```bash
kubectl apply -f C:\PlatformEngineeringDemo\mgmtCluster\bootstrap\control-plane\compositions\prod-cluster-definitions.yaml
```

### Step 3 : XRC
The XRC file is at `C:\PlatformEngineeringDemo\mgmtCluster\bootstrap\control-plane\compositions\prod-cluster-comp-final.yaml`, and it will need some edits before you apply it.

This resource definition contains multiple resources. Below is what each one does and why it is included:

1. crossplane-resourcegroup: for each new application, we create a dedicated resource group to hold that app's Azure resources.

2. crossplane-workload-uai: each application gets its own [User Assigned Identity (UAI)](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp), which is used for [K8s Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster) so workloads can authenticate to Azure without embedded secrets.

3. crossplane-get-cluster-details: because this XRC sets up workload identity, we need to create federated identity credentials in Microsoft Entra for the UAI. For that, we need the `oidcIssuerUrl` from the AKS cluster. To read those cluster properties, we [import the existing AKS cluster into Crossplane](https://docs.crossplane.io/latest/guides/import-existing-resources/) (the one from the previous step, or another equivalent cluster). We set Crossplane management policy to `Observe` and provide the Azure cluster name and resource group, which means Crossplane reads the resource but does not change it. Key snippet:

```yaml
  apiVersion: containerservice.azure.upbound.io/v1beta1
  kind: KubernetesCluster
  metadata:
    annotations:
      crossplane.io/external-name: my56cluster
  spec:
    managementPolicies: ["Observe"]
    forProvider:
      resourceGroupName: my56app-kzzj2
```
This resource returns the `oidcIssuerUrl` and sets it as a label.

4. crossplane-uai-fed: sets up the Federated Identity Credential. Here we use the `appname` input to build the Kubernetes namespace and service account values required for the `subject`. Those namespace and service account objects are created by the [Helm chart](https://github.com/danielsollondon/teaminfra/blob/main/infra/shared/k8s-cluster-config/main-infra-002/templates/app-ns-only.yaml) deployed as part of this flow.

5. crossplane-kv: creates the Azure Key Vault used to store the DB connection string secret and any additional app secrets.

6. crossplane-get-operating-uai-prinID: in later steps we inject the DB connection string into Azure Key Vault using the UAI that Crossplane uses to authenticate with Azure. To do that, we need the principal ID of that Crossplane operating identity and must grant it RBAC permissions to write the secret. We get this by importing the UAI in the same way as the AKS cluster, then setting an annotation with the principal ID.


Important note: at the time of writing, this annotation requires the full resource ID of the UAI.
```yaml
apiVersion: managedidentity.azure.upbound.io/v1beta1
kind: UserAssignedIdentity
metadata:
  annotations:
    crossplane.io/external-name: /subscriptions/<subscriptionId>/resourceGroups/<mgmtClusterResGroup>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/kbl-infra002-uai
spec:
  managementPolicies: ["Observe"]
  forProvider:
    resourceGroupName: <mgmtClusterResGroup>
```
Update this value with your own UAI before deployment.

7. crossplane-role-assign-pri: creates a role assignment for the Crossplane UAI and grants it the `Key Vault Secrets Officer` role on Key Vault.

8. crossplane-db-secret: injects the DB connection string secret into Key Vault.

9. crossplane-role-assign-reader: the Kubernetes workload identity UAI used by the app namespace needs read access to Key Vault so it can read the DB connection string key. Here we assign that UAI the `Key Vault Secrets User` role.

10. create-argo-app: deploys the [app](https://github.com/danielsollondon/teaminfra/infra/shared/k8s-cluster-config/main-infra-002) and passes values to the Helm chart during deployment using the app-of-apps pattern.


11. Add an environment configuration
This composition can be deployed on an existing Kubernetes cluster with Argo, but you need a way for it to know which cluster it should connect to and configure. There are several options:
  * Use [Crossplane Environment Configurations (Alpha)](https://docs.crossplane.io/latest/concepts/environment-configs/): this stores shared configuration (similar to a Kubernetes ConfigMap) that can be patched into resources in a composition.
  * Use region input and transform it to a cluster name: similar to how location is handled, where a user provides EU or US and a [Crossplane map transform](https://docs.crossplane.io/latest/concepts/patch-and-transform/#map-transforms) in the XRC maps that to a valid Azure region.
  * Use Fleet: you can avoid specifying a cluster name directly by using a preconfigured [AKS Fleet Manager](https://marketplace.upbound.io/providers/upbound/provider-azure-containerservice/latest/resources/containerservice.azure.upbound.io/KubernetesFleetManager/v1beta1) to coordinate workload placement based on inputs such as location or environment. This must be set up ahead of time.

For this example, we will use Crossplane Environment Configuration and add the staging cluster configuration there.

12. Enable the environment configuration feature in Crossplane: [--enable-environment-configs](https://docs.crossplane.io/latest/concepts/environment-configs/#enable-environmentconfigs).

13. Create the configuration
Create an EnvironmentConfig on the management cluster. This is where you store shared values (for example, downstream cluster name, resource group, and identity inputs) so the composition can patch them into resources.

Add this file to `mgmtCluster/bootstrap/control-plane/`:

```bash
# Update the values below with the outputs you captured in Step 2.
dsClusterName=<DOWNSTREAM CLUSTER NAME> # example: my56cluster
dsCluRgname=<DOWNSTREAM CLUSTER RG NAME> # example: my56app-dde0064afd2f

# This is the kubelet user-assigned identity used to create the management cluster.
kblAksUai=kbl-infra002-uai
mgmtClusterRg=rg-aks-pe-1598504785
kblAksUaiId=$(az identity show --name $kblAksUai  --resource-group $mgmtClusterRg --query id --output tsv)

cat > envConfig.yaml <<EOF
apiVersion: apiextensions.crossplane.io/v1alpha1
kind: EnvironmentConfig
metadata:
  name: base-app-config-team01
  namespace: upbound-system
data:
  clustername: $dsClusterName
  clusterrgname: $dsCluRgname
  kblaksuaiid: $kblAksUai
  mgmtclusterrg: $mgmtClusterRg
EOF
```

PowerShell alternative:

```powershell
# Update the values below with the outputs you captured in Step 2.
$dsClusterName = "<DOWNSTREAM CLUSTER NAME>" # example: my56cluster
$dsCluRgname = "<DOWNSTREAM CLUSTER RG NAME>" # example: my56app-dde0064afd2f

# This is the kubelet user-assigned identity used to create the management cluster.
$kblAksUai = "kbl-identity-1598504785"
$mgmtClusterRg = "rg-aks-pe-1598504785"
$kblAksUaiId=$(az identity show --name $kblAksUai  --resource-group $mgmtClusterRg --query id --output tsv)

@"
apiVersion: apiextensions.crossplane.io/v1alpha1
kind: EnvironmentConfig
metadata:
  name: base-app-config-team01
  namespace: upbound-system
data:
  clustername: $dsClusterName
  clusterrgname: $dsCluRgname
  kblaksuaiid: $kblAksUai
  mgmtclusterrg: $mgmtClusterRg
"@ | Set-Content -Path .\envConfig.yaml
```

Note:
- The Crossplane managedidentity provider is case-sensitive for external resource IDs. Keep this format and casing when referencing identity IDs:
  - `/subscriptions/<subId>/resourceGroups/<mgmtclusterrg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$kblAksUai = "kbl-identity-1598504785"`

14. Commit the file to the repo under `mgmtCluster/bootstrap/control-plane/`; Argo will apply it.

15. Add the XRD to the cluster

```bash
kubectl apply -f C:\PlatformEngineeringDemo\mgmtCluster\bootstrap\control-plane\compositions\prod-cluster-definitions.yaml
```

16.   Deploy workloads to the cluster
This step creates two workloads and deploys apps that can read the DB connection string from Key Vault.

```bash
appname=baseapp01app
appname2=baseapp02app
teamname=team01
repourl="https://github.com/oreakinodidi98/PlatformEngineeringDemo"
repopath="workloads/team01/infra002"

cat > team1-apps.yaml <<EOF
apiVersion: compute.example.com/v1alpha1
kind: base-stateful-app
metadata:
  name: $appname
spec:
  location: EU
  appname: $appname
  repourl: $repourl
  repopath: $repopath
---
apiVersion: compute.example.com/v1alpha1
kind: base-stateful-app
metadata:
  name: $appname2
spec:
  location: EU
  appname: $appname2
  repourl: $repourl
  repopath: $repopath
EOF
```

PowerShell alternative:

```powershell
$appname = "baseapp01app"
$appname2 = "baseapp02app"
$teamname = "team01"
$repourl = "https://github.com/oreakinodidi98/PlatformEngineeringDemo"
$repopath = "workloads/team01/infra002"

@"
apiVersion: compute.example.com/v1alpha1
kind: base-stateful-app
metadata:
  name: $appname
spec:
  location: EU
  appname: $appname
  repourl: $repourl
  repopath: $repopath
---
apiVersion: compute.example.com/v1alpha1
kind: base-stateful-app
metadata:
  name: $appname2
spec:
  location: EU
  appname: $appname2
  repourl: $repourl
  repopath: $repopath
"@ | Set-Content -Path .\prod-team1-apps.yaml
```

Commit this file to the repo under `C:\PlatformEngineeringDemo\downstreamInfra\team01`; Argo will apply it.

17. Check the deployment
Use these Crossplane commands to verify claims, managed resources, and events:

```bash
# List claims for the CRD
kubectl get base-stateful-app.compute.example.com

# Describe each claim
kubectl describe base-stateful-app.compute.example.com/$appname
kubectl describe base-stateful-app.compute.example.com/$appname2

# Show all managed Crossplane resources
kubectl get managed

# Describe a specific managed resource
kubectl describe FederatedIdentityCredential.managedidentity.azure.upbound.io/baseapp02app-jzm7r

# Show events
kubectl get events
```

18.  Check that the secret is available to the pod

```bash
# Get kubeconfig for the downstream AKS cluster
dsClusterName=<DOWNSTREAM CLUSTER NAME> # example: my56cluster
dsCluRgname=<DOWNSTREAM CLUSTER RG NAME> # example: my56app-kzzj2

az aks get-credentials --resource-group $dsCluRgname --name $dsClusterName --file DSCLU01

# Check the connection string in each app pod environment
KUBECONFIG=DSCLU01 kubectl exec -it busybox-secrets-store-inline-user-msi -n $appname printenv | grep db-conn
KUBECONFIG=DSCLU01 kubectl exec -it busybox-secrets-store-inline-user-msi -n $appname2 printenv | grep db-conn
```

PowerShell alternative:

```powershell
$dsClusterName = "<DOWNSTREAM CLUSTER NAME>" # example: my56cluster
$dsCluRgname = "<DOWNSTREAM CLUSTER RG NAME>" # example: my56app-kzzj2

az aks get-credentials --resource-group $dsCluRgname --name $dsClusterName --file DSCLU01

$env:KUBECONFIG = "DSCLU01"
kubectl exec -it busybox-secrets-store-inline-user-msi -n $appname printenv | Select-String db-conn
kubectl exec -it busybox-secrets-store-inline-user-msi -n $appname2 printenv | Select-String db-conn
```

19. Clean up

```bash
rm team1-apps.yaml
```

PowerShell alternative:

```powershell
Remove-Item .\team1-apps.yaml
```

Commit and push to the repo.

## Recap
You just simulated a preconfigured application environment end to end. The flow set up a shared team AKS cluster, created the workload identity path (identity, namespace, and service account), created Azure resources (Key Vault, secret objects, and user-assigned identity), created an Argo application, and deployed an app that can read the Key Vault secret without using a password.

The key point is that the developer did not need to directly manage Kubernetes objects, pipeline wiring, or raw Azure resource setup. Those platform details were handled by the platform configuration and automation layers.

This section is meant to help you understand the pattern, not to present a full production best-practice implementation. If you want a more complete reference architecture, use this example: [Azure AKS platform engineering sample](https://github.com/Azure-Samples/aks-platform-engineering).
