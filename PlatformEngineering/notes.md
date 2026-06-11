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
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
```

Notes:

- The finalizer ensures child applications and their resources are deleted when the parent application is deleted.
- Replace `<GITHUB_USER>` and `<GITHUB_REPO>` with your actual values.

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

## Stage 10: Deploy Preconfigured, Standardized Solutions in Azure (Part 2)

In this stage, I stop deploying each resource manually and start exposing a standard platform request that teams can use.

### What This Stage Does

1. Defines a custom API for a standardized AKS deployment.
2. Connects that API to a Composition that creates all required resources.
3. Lets a team deploy the full setup by submitting one claim.
4. Validates that all generated resources reconcile successfully.

### Key Concepts in Plain Terms

1. `XRD` defines the API shape and allowed fields.
2. `Composition` defines what infrastructure and Kubernetes objects are created.
3. `XR` is the generated composite resource instance.
4. `Claim (XC)` is the user-facing request submitted in a namespace.
5. `Patches` map claim input values into child resources.

### Step 1: Create the XRD

I create the XRD so platform users can request a staging AKS environment through a controlled schema.

- File: `mgmtCluster/bootstrap/control-plane/xp-staging-cluster-definitions.yaml`
- Required fields: `location`, `clustername`, `teamname`
- Optional fields: `repourl`, `repopath`

Validate it:

```bash
kubectl get compositeresourcedefinitions
kubectl describe compositeresourcedefinition staging-aks.compute.example.com
```

### Step 2: Create the Composition

I create the Composition that implements the actual resources behind the API.

- File: `mgmtCluster/bootstrap/control-plane/xp-staging-cluster-comp.yaml`
- Typical composed resources:
  - ResourceGroup
  - KubernetesCluster
  - Helm ProviderConfig
  - Argo Helm Release
  - Kubernetes ProviderConfig
  - Argo Application Object

Important implementation note:

- For composed `ProviderConfig` resources, set `readinessChecks` to `None`.

### Step 3: Submit a Claim

I submit one claim with only the platform-approved inputs.

```bash
name=my56app
clustername=my56cluster
teamname=team01
repourl="https://github.com/danielsollondon/teaminfra/"
repopath="infra/shared/k8s-cluster-config/sh01-wus2-01"

cat <<EOF | kubectl apply -f -
apiVersion: compute.example.com/v1alpha1
kind: staging-aks
metadata:
  name: $name
spec:
  clustername: $clustername
  teamname: $teamname
  location: EU
  repourl: $repourl
  repopath: $repopath
EOF
```

### Step 4: Validate Progress and Health

I check the claim first:

```bash
kubectl describe staging-aks.compute.example.com/$name
```

Then I check all managed resources:

```bash
kubectl get managed
```

If there is an issue, I inspect the specific resource:

```bash
kubectl describe kubernetescluster.containerservice.azure.upbound.io/<cluster-name>
```

What I look for:

1. Claim events such as `SelectComposition` and `ComposeResources`.
2. `SYNCED` and `READY` states on managed resources.
3. Provider error messages in `Status.Conditions` and `Events`.

### Recap

At this point, I have a standardized cluster request flow:

1. Teams submit a simple claim.
2. Crossplane enforces platform standards through XRD + Composition.
3. The underlying complexity stays centralized in platform definitions.
4. Everything is still tracked and auditable through Git and Kubernetes state.

This is a baseline platform pattern. A full production solution will include additional policies, dependencies, and app-environment components.

### Keep or Clean Up

- Keep the cluster running for the next stage.
- If needed, delete the claim and composed resources:

```bash
kubectl delete staging-aks.compute.example.com/my56app
```

## Links

[Crossplane](https://www.crossplane.io/?_gl=1*1dro6di*_ga*MTY2NDM4MzI0Ni4xNzgxMTY2MzY1*_ga_SFCPQYSLHY*czE3ODExNjYzNjUkbzEkZzAkdDE3ODExNjYzNjUkajYwJGwwJGgw)
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
