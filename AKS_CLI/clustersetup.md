# AKS Agentic CLI — Cluster Mode Setup Guide

> The agentic CLI for AKS supports two deployment modes. This guide covers **Cluster mode**, which deploys the agent as a pod within your AKS cluster using Helm.

---

## Overview

| Aspect           | Detail                                                                                                 |
|------------------|--------------------------------------------------------------------------------------------------------|
| **Deployment**   | Deploys the agent as a pod within your AKS cluster using Helm                                          |
| **Auth**         | Uses service account and optional workload identity for secure access to cluster and Azure resources    |
| **Use case**     | Production scenarios, shared environments, and running the agent close to cluster resources             |
| **Requirements** | Namespace, service account with RBAC permissions, and (optionally) workload identity for Azure access   |

---

## Prerequisites

1. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`) installed
2. An existing AKS cluster deployed (see [aksdeploycluster.ps1](aksdeploycluster.ps1))
3. `kubectl` configured and connected to the cluster
4. Service account with [RBAC permissions](https://learn.microsoft.com/en-us/azure/aks/agentic-cli-for-aks-service-account-workload-identity-setup#step-1-create-the-kubernetes-service-account-mandatory)
5. Write access to the target Kubernetes namespace for deployment
6. *(Optional but recommended)* Workload identity setup for enhanced security
7. **Enable local auth on Cognitive Services** (required if your subscription enforces Entra ID-only):

   ```powershell
   Get-AzCognitiveServicesAccount `
     | Where-Object { $_.DisableLocalAuth -eq $true -and $_.AccountName -and $_.ResourceGroupName -and $_.Id } `
     | ForEach-Object {
         Update-AzTag -ResourceId $_.Id -Tag @{ SecurityControl = 'Ignore' } -Operation Merge | Out-Null
         Set-AzCognitiveServicesAccount -ResourceGroupName $_.ResourceGroupName `
           -Name $_.AccountName -DisableLocalAuth $false | Out-Null
       }
   ```

---

## Setup Steps

### 1. Install the AKS Agent Extension

```powershell
az extension add --name aks-agent
```

### 2. Verify Installation

```powershell
az extension list          # confirm aks-agent appears
az aks agent --help        # confirm the command is available
```

### 3. Initialize the Agent (Cluster Mode)

```powershell
az aks agent-init --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME>
```

When prompted:

- Select **Option 1** for cluster mode.
- enter namespace
- Configure your LLM provider and API key.
- Provide service account details.
- The initialization will deploy the agent using Helm.

> **Note:** The AKS Model Context Protocol (MCP) server is enabled by default.

### 4. Verify Deployment

```powershell
az aks agent --status --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>
```

### 5. Run Your First Query

```powershell
az aks agent "How many nodes are in my cluster?" `
  --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>
```

---

## Example Prompts

```powershell
# Cluster info
az aks agent "How many nodes are in my cluster?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>
az aks agent "What is the Kubernetes version on the cluster?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>

# Troubleshooting
az aks agent "Why is coredns not working on my cluster?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>
az aks agent "Why is my cluster in a failed state?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>
```

---

## Advanced Options

### Non-Interactive Mode

Use `--no-interactive` to skip the interactive prompt and get a single response:

```powershell
az aks agent "How many pods are in the kube-system namespace" `
  --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE> `
  --model=azure/gpt-4o --no-interactive
```

### Show Tool Output

Add `--show-tool-output` to see the raw tool calls the agent made:

```powershell
az aks agent "Why are the pods in CrashLoopBackOff in the kube-system namespace" `
  --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE> `
  --model=azure/gpt-4o --no-interactive --show-tool-output
```

---

## Interactive Mode Commands

Enter `/` inside interactive mode to access these subcommands:

| Command      | Description                                                      |
|--------------|------------------------------------------------------------------|
| `/exit`      | Leave interactive mode                                           |
| `/help`      | Show help with all commands                                      |
| `/clear`     | Clear screen and reset conversation context                      |
| `/tools`     | Show available toolsets and their status                         |
| `/auto`      | Toggle display of tool outputs after responses                   |
| `/last`      | Show all tool outputs from the last response                     |
| `/run`       | Run a Bash command and optionally share it with the LLM          |
| `/shell`     | Drop into an interactive shell, then optionally share with LLM   |
| `/context`   | Show conversation context size and token count                   |
| `/show`      | Show specific tool output in a scrollable view                   |
| `/feedback`  | Provide feedback on the agent's response                         |

---

## Cleanup

```powershell
az aks agent-cleanup --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --namespace <NAMESPACE>
```