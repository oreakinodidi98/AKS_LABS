# AKS Agentic CLI — Client Mode Setup Guide

> The agentic CLI for AKS supports two deployment modes. This guide covers **Client mode**, which runs the agent locally via Docker using your Azure credentials.

---

## Overview

| Aspect         | Detail                                                                 |
|----------------|------------------------------------------------------------------------|
| **Deployment** | Runs the agent locally using Docker                                    |
| **Auth**       | Uses your local Azure credentials and cluster user credentials         |
| **Use case**   | Development, testing, and local troubleshooting                        |

---

## Prerequisites

1. [Docker Desktop](https://www.docker.com/get-started/) installed and running
2. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`) installed
3. An existing AKS cluster deployed (see [`aksdeploy.ps1`](aksdeploy.ps1))
4. **Enable local auth on Cognitive Services** (required if your subscription enforces Entra ID-only):

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

### 3. Initialize the Agent (Client Mode)

```powershell
az aks agent-init --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME>
```

When prompted:

- Select **Option 2** for client mode.
- Configure your LLM provider and API key.

> **Note:** The agent will automatically pull the required Docker images on first run.  
> The AKS Model Context Protocol (MCP) server is enabled by default.

### 4. Run Your First Query

```powershell
az aks agent "How many nodes are in my cluster?" \
  --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --mode client
```

---

## Example Prompts

```powershell
# Cluster info
az aks agent "How many nodes are in my cluster?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --mode client
az aks agent "What is the Kubernetes version on the cluster?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --mode client

# Troubleshooting
az aks agent "Why is coredns not working on my cluster?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --mode client
az aks agent "Why is my cluster in a failed state?" --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --mode client
```

---

## Advanced Options

### Non-Interactive Mode

Use `--no-interactive` to skip the interactive prompt and get a single response:

```powershell
az aks agent "How many pods are in the kube-system namespace" \
  --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> \
  --mode client --model=azure/gpt-4o --no-interactive
```

### Show Tool Output

Add `--show-tool-output` to see the raw tool calls the agent made:

```powershell
az aks agent "Why are the pods in CrashLoopBackOff in the kube-system namespace" \
  --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> \
  --mode client --model=azure/gpt-4o --no-interactive --show-tool-output
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
az aks agent-cleanup --resource-group <RESOURCE_GROUP> --name <CLUSTER_NAME> --mode client
```