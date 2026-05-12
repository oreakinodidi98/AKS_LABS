# AKS Labs

Hands-on labs, deployment scripts, and reference material for Azure Kubernetes Service and the broader Kubernetes ecosystem. Everything here is built to be practical — scripts you can run, manifests you can deploy, and notes you can reference when you need them.

---

## Table of Contents

- [AKS Labs](#aks-labs)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
  - [Repo Structure](#repo-structure)
    - [Fundamentals](#fundamentals)
    - [AKS CLI](#aks-cli)
    - [AKS Automatic](#aks-automatic)
    - [Infrastructure as Code](#infrastructure-as-code)
    - [AI and ML Workloads](#ai-and-ml-workloads)
    - [Ollama on Kubernetes](#ollama-on-kubernetes)
    - [AKS Agent Skills](#aks-agent-skills)
    - [App Modernization](#app-modernization)
    - [Networking](#networking)
    - [Security](#security)
    - [Policies](#policies)
    - [GitOps](#gitops)
    - [Argo CD](#argo-cd)
    - [Argo Rollouts](#argo-rollouts)
    - [Argo Workflows](#argo-workflows)
    - [App Gateway for Containers](#app-gateway-for-containers)
    - [Azure Red Hat OpenShift](#azure-red-hat-openshift)
    - [MySQL](#mysql)
  - [Prerequisites](#prerequisites)

---

## Quick Start

```powershell
az aks start --resource-group <myresourcegroup> --name <myakscluster>
Set-Alias k kubectl
kubectl create namespace pets
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml -n pets
kubectl get all -n pets
```

Most labs include their own setup scripts (`setup.ps1` or similar) and deploy scripts that handle resource group creation, cluster provisioning, and configuration. The root-level [`aksdeploy.ps1`](aksdeploy.ps1) and [`aksdeployKV.ps1`](aksdeployKV.ps1) scripts provision a standard AKS cluster with sensible defaults.

---

## Repo Structure

### Fundamentals

[`Fundamentals/`](Fundamentals/)

Core Kubernetes concepts — workload resources (Deployments, StatefulSets, DaemonSets, Jobs), multi-container Pod patterns (sidecar, init containers), persistent storage with PVs and PVCs, deployment strategies (blue/green, canary, rolling updates), and essential `kubectl` commands. Includes working manifests for network policies, ingress, VPA, and sidecar patterns.

### AKS CLI

[`AKS_CLI/`](AKS_CLI/)

Step-by-step guides for provisioning AKS clusters and setting up client tooling using the Azure CLI. Two modes covered:
- **Cluster mode** — deploy the AKS agentic CLI as a pod within your cluster
- **Client mode** — run the agent locally via Docker with your Azure credentials

### AKS Automatic

[`aks-automatic/`](aks-automatic/)

Terraform modules for deploying AKS Automatic clusters — the fully managed SKU that handles node management, scaling, and security configuration for you.

### Infrastructure as Code

[`k8s-terraform/`](k8s-terraform/)

Terraform-based AKS deployment with modular structure covering the cluster itself, Key Vault integration, and Log Analytics. Includes environment setup scripts and output definitions.

### AI and ML Workloads

[`AIandML/`](AIandML/)

Running AI and ML workloads on AKS using **Ray** and **KubeRay**. Covers distributed training with Ray Train, model serving with Ray Serve, distributed data processing with Ray Data, GPU node pools, BlobFuse storage integration, HPA/cluster autoscaler configuration, and Azure Monitor integration. Also includes notes on **KAITO** for automated GPU provisioning and RAGEngine for retrieval-augmented generation workloads.

### Ollama on Kubernetes

[`Ollama/`](Ollama/)

Deploying and running large language models on AKS using Ollama, managed through ArgoCD. Covers model management, GPU scheduling, scaling for team use, and multi-stage deployment manifests (dev, preload, prod). Includes Python scripts for calling the Ollama API and monitoring configurations.

### AKS Agent Skills

[`AKS_agent/`](AKS_agent/)

Agent skills for Azure Kubernetes Service — bringing production-grade AKS guidance, troubleshooting checklists, and guardrails directly into AI agents like GitHub Copilot and Claude. Includes setup guides, skill definitions, and a presentation deck on building agentic operations for AKS and ARO.

### App Modernization

[`Aks_AppMod/`](Aks_AppMod/)

Modernizing applications for AKS, demonstrated with the Spring PetClinic app. Walks through running the application locally (with H2 or PostgreSQL), containerizing, and deploying to AKS.

### Networking

[`Networking/`](Networking/)

AKS networking labs covering **Advanced Container Networking Services (ACNS)** — Cilium-based FQDN filtering, L7 network policies, container network flow logs, and network observability with Azure Managed Grafana. Includes deployment scripts with Azure CNI Overlay and Cilium dataplane configuration, plus working network policy manifests.

### Security

[`Security/`](Security/)

Three focus areas:
- **CKS** — Certified Kubernetes Security Specialist lab environment with cluster setup, hardening, microservice vulnerability minimization, system hardening, supply chain security, and runtime monitoring
- **Container Image** — Container image security best practices
- **Workload Identity** — End-to-end setup for Microsoft Entra Workload ID with federated credentials, Key Vault access, and managed identity configuration

### Policies

[`policies/`](policies/)

OPA/Rego policies for Kubernetes admission control — for example, enforcing that only images from Microsoft Container Registry (MCR) are allowed.

### GitOps

[`GitOps/`](GitOps/)

GitOps concepts and workflow — using a Git repo as the single source of truth for Kubernetes deployments, covering the separation of app source code and manifests, CI/CD pipelines, and why tools like ArgoCD and Flux solve the "Docker Hub to Kubernetes" deployment gap.

### Argo CD

[`argocd/`](argocd/)

Setting up ArgoCD on AKS — installation, CLI setup, deploying applications, and managing the ArgoCD dashboard. Includes deployment and service manifests plus Argo Events integration with Pulsar.

### Argo Rollouts

[`argorollouts/`](argorollouts/)

Progressive delivery with Argo Rollouts — blue-green and canary deployment strategies with preview services, promotion, and rollback workflows. Includes rollout manifests and CLI plugin setup for Windows.

### Argo Workflows

[`argoworkflows/`](argoworkflows/)

Kubernetes-native workflow orchestration with Argo Workflows — DAG-based workflows, workflow templates, CI/CD pipelines, and CLI tooling for both Linux and Windows.

### App Gateway for Containers

[`Appgateway/`](Appgateway/)

Deploying the Application Gateway for Containers (AGC) ALB controller into an AKS cluster — managed and bring-your-own deployment strategies.

### Azure Red Hat OpenShift

[`ARO/`](ARO/)

Provisioning and configuring Azure Red Hat OpenShift clusters — VNet/subnet setup, quota requirements, managed identity configuration, and notes on Red Hat Developer Lightspeed. Includes both Bash and PowerShell setup scripts.

### MySQL

[`MySQL/`](MySQL/)

MySQL fundamentals — core SQL concepts (DDL, DML, DQL, DCL), database and table creation, querying, and command-line operations. Useful reference material for database-backed workloads running on AKS.

---

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and authenticated (`az login`)
- `kubectl` configured and connected to your cluster
- PowerShell (most scripts are written for `pwsh`)
- Docker Desktop (for container builds and local testing)
- Terraform (for IaC labs)
- Python 3.10+ (for AI/ML and Ollama labs)