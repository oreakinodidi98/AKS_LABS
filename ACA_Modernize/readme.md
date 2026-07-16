# ACA Containerize and Modernize with Azure

LAb to learn how to quickly deploy powerful, flexible AI-powered applications to Azure Container Apps

This lab helps you quickly deploy powerful, flexible AI-powered applications to Azure Container Apps.

## Table of Contents

- [ACA Containerize and Modernize with Azure](#aca-containerize-and-modernize-with-azure)
  - [Table of Contents](#table-of-contents)
  - [Who This Is For](#who-this-is-for)
  - [How to Use This Guide](#how-to-use-this-guide)
  - [Learning Objectives](#learning-objectives)
  - [Lab Flow At a Glance](#lab-flow-at-a-glance)
  - [Suggested Time Budget](#suggested-time-budget)
  - [Azure Container Apps Dynamic Sessions](#azure-container-apps-dynamic-sessions)
  - [Architecture Snapshot](#architecture-snapshot)
    - [Pre-REq](#pre-req)
    - [Before You Start Checklist](#before-you-start-checklist)
    - [Required Environment Variables](#required-environment-variables)
    - [Role Assignments](#role-assignments)
    - [Role Assignment Best Practices](#role-assignment-best-practices)
    - [Verification Commands](#verification-commands)
    - [AI-Focused Introduction to Azure Container Apps](#ai-focused-introduction-to-azure-container-apps)
  - [Lab Environment Setup](#lab-environment-setup)
    - [Success Criteria for This Section](#success-criteria-for-this-section)
    - [Task 1 - Create GPU-Enabled Container App via Azure Portal](#task-1---create-gpu-enabled-container-app-via-azure-portal)
    - [Task 2 - Test GPU Image Generation Application](#task-2---test-gpu-image-generation-application)
    - [Task 3 - Keep One Replica Warm (Reduce Cold Start)](#task-3---keep-one-replica-warm-reduce-cold-start)
    - [Task 4 - Monitor GPU Performance](#task-4---monitor-gpu-performance)
  - [Troubleshooting](#troubleshooting)
    - [Common Issues and Solutions](#common-issues-and-solutions)
  - [Deploy Azure OpenAI](#deploy-azure-openai)
    - [Success Criteria for This Section](#success-criteria-for-this-section-1)
  - [Task 1 - Reconfigure the GPU App to Run Ollama](#task-1---reconfigure-the-gpu-app-to-run-ollama)
  - [Task 2 - Pull Ollama Models from the Portal Console](#task-2---pull-ollama-models-from-the-portal-console)
  - [Task 3 - Compare Model Quality with Prompt Pack](#task-3---compare-model-quality-with-prompt-pack)
  - [Task 4 - Explore the Ollama REST API](#task-4---explore-the-ollama-rest-api)
    - [4.1 Set the container app endpoint as an environment variable](#41-set-the-container-app-endpoint-as-an-environment-variable)
    - [4.2 List installed models](#42-list-installed-models)
    - [4.3 Show model metadata (pick any deployed model)](#43-show-model-metadata-pick-any-deployed-model)
    - [4.4 Generate a streamed response](#44-generate-a-streamed-response)
    - [4.5 Return just the response](#45-return-just-the-response)
  - [Persist models and reduce cold starts in production](#persist-models-and-reduce-cold-starts-in-production)
  - [Ollama \& Open-Source Models](#ollama--open-source-models)
    - [Aim](#aim)
    - [What to Capture in This Section](#what-to-capture-in-this-section)
    - [LangChain](#langchain)
    - [Code Interpreters](#code-interpreters)
    - [Task 1 - Setup](#task-1---setup)
  - [MCP Shell Integration](#mcp-shell-integration)
    - [What to Capture in This Section](#what-to-capture-in-this-section-1)
  - [Goose AI Agent](#goose-ai-agent)
    - [What to Capture in This Section](#what-to-capture-in-this-section-2)
  - [Azure Container Apps Dynamic Sessions](#azure-container-apps-dynamic-sessions-1)
    - [What to Capture in This Section](#what-to-capture-in-this-section-3)
  - [Build LangChain Application](#build-langchain-application)
    - [What to Capture in This Section](#what-to-capture-in-this-section-4)
  - [Deploy and Test](#deploy-and-test)
    - [What to Capture in This Section](#what-to-capture-in-this-section-5)
  - [🐛 Troubleshooting](#-troubleshooting)
    - [Common Issues](#common-issues)
    - [Getting Help](#getting-help)
    - [Escalation Path](#escalation-path)
  - [Additional Resources](#additional-resources)
    - [Azure Documentation](#azure-documentation)
    - [Sample Code \& Tutorials](#sample-code--tutorials)
    - [Tools \& SDKs](#tools--sdks)

## Who This Is For

This guide is for platform engineers, cloud engineers, and app developers who want a practical, end-to-end AI app modernization flow on Azure Container Apps (ACA), including GPU-backed workloads.

## How to Use This Guide

- Follow tasks in order from top to bottom.
- Run either Bash or PowerShell commands for each step (do not mix shells in the same terminal session).
- Keep your terminal open so environment variables remain available.
- Use the verification checks after each major step before moving forward.
- If a command fails, use the Troubleshooting section before retrying.

## Learning Objectives

By the end of this Demo, you will be able to:

- Deploy containerized AI applications on Azure Container Apps with GPU support
- Create and configure Azure OpenAI resources with GPT models
- Run open-source LLMs (Ollama) on serverless GPUs for cost-efficient inferencing
- Set up Azure Container Apps Dynamic Session Pools for secure code execution
- Build AI agents using MCP (Model Context Protocol) and Goose
- Integrate multiple AI services with LangChain
- Configure proper RBAC (Role-Based Access Control) for Azure resources
- Implement enterprise security and compliance best practices
- Optimize AI workloads for cost and performance

## Lab Flow At a Glance

1. Complete prerequisites and set environment variables.
2. Deploy a GPU-enabled Azure Container App.
3. Validate image generation and warm-replica behavior.
4. Monitor GPU/container health from Console and Debug Console.
5. Continue with Azure OpenAI, Ollama, MCP, Goose, and LangChain integration.
6. Deploy the full application and validate end-to-end behavior.

## Suggested Time Budget

- Prerequisites and setup: 15-25 minutes
- ACA GPU deployment and validation: 20-35 minutes
- AI service integration (OpenAI/Ollama/MCP/LangChain): 30-60 minutes
- End-to-end testing and troubleshooting: 20-30 minutes

## Azure Container Apps Dynamic Sessions

Azure Container Apps Dynamic Sessions provides secure, isolated Python environments where you can execute untrusted code safely. This is perfect for:

- Running AI-generated code in sandboxed environments
- Building interactive coding tutorials and learning platforms
- Creating AI agents that can write and execute code
- Data analysis applications that process user-submitted code

## Architecture Snapshot

- Azure Container Apps hosts your app workloads.
- Serverless GPUs accelerate model inference (for supported workloads).
- Azure OpenAI provides hosted model endpoints.
- Ollama provides local/open-source model serving options.
- Dynamic Sessions provide isolated code execution environments.
- MCP + Goose + LangChain coordinate agent and tool workflows.

### Pre-REq

### Before You Start Checklist

- Confirm you can sign in to Azure and select the correct subscription.
- Confirm your selected region has available ACA GPU capacity.
- Confirm required resource providers are registered.
- Confirm you have permissions for role assignments in your subscription/resource group.
- Confirm your shell choice for this lab:
   - Bash: use `export ...`
   - PowerShell (`pwsh`): use `$env:...`
- Confirm internet access to Azure endpoints and package repositories.

Before starting the lab, complete these setup steps:

1. **Install Azure CLI**
   ```bash
   # Follow instructions at: https://learn.microsoft.com/cli/azure/install-azure-cli
   az --version
   ```

2. **Login to Azure**
   ```bash
   az login
   az account show
   ```

3. **Register Resource Providers** (one-time per subscription)
   ```bash
   az provider register --namespace Microsoft.CognitiveServices --wait
   az provider register --namespace Microsoft.App --wait
   az provider register --namespace Microsoft.OperationalInsights --wait
   ```

4. **Install Python Dependencies**
   ```bash
   sudo apt update
   sudo apt install -y python3-pip python3-venv python3-dev build-essential
   ```

5. **Fix Line Endings** (for WSL users)
   ```bash
   sudo apt install dos2unix
   ```

### Required Environment Variables

Set these variables for the lab:

> [!Tip]
> Copy this section into a shell script for repeatability:
> - Bash: `setup-env.sh`
> - PowerShell: `setup-env.ps1`
>
> This makes reruns and troubleshooting much faster.

```bash
# User Information
export USER_PRINCIPAL_NAME=$(az ad signed-in-user show --query userPrincipalName -o tsv | tr -d '\r')
export USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv | tr -d '\r')

# Azure Resources
export RG="aca-langchain-rg-${USER}-$RANDOM"
export LOC="eastus"
export POOL="aca-langchain-py-${USER}-$RANDOM"
export OPENAI_NAME="openai-aca-${USER}-$RANDOM"
export OPENAI_DOMAIN="openai-aca-${USER}-$RANDOM"
export DEPLOYMENT_NAME="gpt-5.4"

# Generated after resource creation
export POOL_ID=$(az containerapp sessionpool show --name $POOL --resource-group $RG --query id -o tsv | tr -d '\r')
export POOL_MGMT=$(az containerapp sessionpool show --name $POOL --resource-group $RG --query 'properties.poolManagementEndpoint' -o tsv | tr -d '\r')
export OPENAI_ID=$(az cognitiveservices account show --name $OPENAI_NAME --resource-group $RG --query id -o tsv | tr -d '\r')
export OPENAI_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_NAME --resource-group $RG --query 'properties.endpoint' -o tsv | tr -d '\r')

# Application Configuration
export DS_POOL_ENDPOINT="$POOL_MGMT"
export AZURE_OPENAI_ENDPOINT="$OPENAI_ENDPOINT"
export AZURE_OPENAI_DEPLOYMENT_NAME="gpt-35-turbo"
export AZURE_OPENAI_API_VERSION="2024-02-15-preview"
```

If you're using PowerShell (`pwsh`), use this equivalent:

```powershell
# User Information
$env:USER_PRINCIPAL_NAME = (az ad signed-in-user show --query userPrincipalName -o tsv).Trim()
$env:USER_OBJECT_ID = (az ad signed-in-user show --query id -o tsv).Trim()

# Azure Resources
$random = Get-Random -Minimum 10000 -Maximum 99999
$env:RG = "aca-langchain-rg-$env:USERNAME-$random"
$env:LOCATION = "swedencentral"
$env:POOL = "aca-langchain-py-$env:USERNAME-$random"
$env:OPENAI_NAME = "openai-aca-$env:USERNAME-$random"
$env:OPENAI_DOMAIN = "openai-aca-$env:USERNAME-$random"
$env:DEPLOYMENT_NAME = "gpt-5.4"

# Generated after resource creation
$env:POOL_ID = (az containerapp sessionpool show --name $env:POOL --resource-group $env:RG --query id -o tsv).Trim()
$env:POOL_MGMT = (az containerapp sessionpool show --name $env:POOL --resource-group $env:RG --query properties.poolManagementEndpoint -o tsv).Trim()
$env:OPENAI_ID = (az cognitiveservices account show --name $env:OPENAI_NAME --resource-group $env:RG --query id -o tsv).Trim()
$env:OPENAI_ENDPOINT = (az cognitiveservices account show --name $env:OPENAI_NAME --resource-group $env:RG --query properties.endpoint -o tsv).Trim()

# Application Configuration
$env:DS_POOL_ENDPOINT = $env:POOL_MGMT
$env:AZURE_OPENAI_ENDPOINT = $env:OPENAI_ENDPOINT
$env:AZURE_OPENAI_DEPLOYMENT_NAME = "gpt-5.4"
$env:AZURE_OPENAI_API_VERSION = "2024-02-15-preview"
```

### Role Assignments

You'll need to assign these roles during the lab:

1. **Azure Container Apps Session Executor** (on Session Pool)
   - Grants permission to execute code in dynamic sessions

2. **Contributor** (on Session Pool)
   - Grants permission to manage the session pool resource

3. **Cognitive Services OpenAI User** (on Azure OpenAI)
   - Grants permission to call Azure OpenAI APIs

**PowerShell Scripts Provided:**
- `AssignContainerAppsRole.ps1` - Assigns session pool roles via GUI
- `AssignCognitiveServicesUserRole.ps1` - Assigns OpenAI role via GUI

### Role Assignment Best Practices

- Assign the least privilege needed first, then expand only if required.
- Wait 1-5 minutes after role assignment for RBAC propagation.
- Validate scope carefully:
   - Session roles should target the Session Pool resource ID.
   - OpenAI role should target the Azure OpenAI resource ID.
- Re-run verification commands after assignment before continuing.

### Verification Commands

Check your role assignments:

```bash
# Verify Session Pool roles
az role assignment list \
  --assignee "$USER_PRINCIPAL_NAME" \
  --scope "$POOL_ID" \
  -o table

# Verify Azure OpenAI role
az role assignment list \
  --assignee "$USER_PRINCIPAL_NAME" \
  --scope "$OPENAI_ID" \
  -o table
```

PowerShell equivalent:

```powershell
# Verify Session Pool roles
az role assignment list `
   --assignee "$env:USER_PRINCIPAL_NAME" `
   --scope "$env:POOL_ID" `
   -o table

# Verify Azure OpenAI role
az role assignment list `
   --assignee "$env:USER_PRINCIPAL_NAME" `
   --scope "$env:OPENAI_ID" `
   -o table
```

### AI-Focused Introduction to Azure Container Apps

Why AI workloads benefit from ACA + GPUs

The types of AI workloads that justify ACA serverless GPUs

- Image generation, RAG inferencing, and custom fine-tuned models with bursty demand.
- Serverless GPUs reduce idle burn; container boundaries keep deployment consistent across environments.
- Contrast ACA with AKS for the same workloads (operational overhead, scale-to-zero vs. always-on).

## Lab Environment Setup

### Success Criteria for This Section

By the end of Tasks 1-4, you should have:

- A deployed GPU-enabled ACA application.
- A reachable application URL.
- At least one successful generated image.
- Min replicas set to `1` for warm performance during the lab.
- Verified container-level visibility via Console/Debug Console.

### Task 1 - Create GPU-Enabled Container App via Azure Portal

**Description:** In this task, you'll use the Azure Portal to create a new Container Apps environment and deploy a GPU-enabled AI image generation app. You'll configure it for serverless GPUs and expose it publicly.

**Task 1 outcome:** A running GPU-enabled container app with ingress enabled.

1. **Open a browser and sign in to Azure:**
   - Go to the Azure Portal: `https://portal.azure.com`
   - Sign in with your account.

2. **Start creating a new Container App:**
   - In the top search bar, type `Container App`.
   - Select **Container App** from the results.
   - Click **Create**, then choose **Container App**.
   - This opens the Container App creation wizard.

3. **Configure Basic settings:**
   In the **Basics** tab, configure the following values.

   **Project details:**
   - **Subscription:** Select your Azure subscription
   - **Resource group:** Click **Create new resource group** and enter `my-gpu-demo-group`
   - **Container app name:** Enter `my-gpu-demo`
   - **Deployment source:** Select **Container image**

   **Container Apps environment:**
   - **Region:** Select **West US 3**

     **Note:** Other supported regions include Sweden Central and Australia East, East US 2, and North Central US.

   - **Container Apps environment:** Keep the default.
   - Click **Next: Container >** to continue

4. **Configure Container settings:**
   In the **Container** tab, use the following settings.

   - Choose **Use Quickstart Image**
   - Select **GPU Hello World Container** from the drop-down list

   **Workload profile and GPU configuration:**
   - These options are enabled with the quickstart image:
   - **Workload profile:** Select **Consumption - Up to 4 vCPUs, 8 GiB memory**
   - **GPU:** Check the **Enable GPU** checkbox
   - **GPU Type:** Select **Consumption-GPU-NC8as-T4 - Up to 8 vCPUs, 56 GiB memory**

   The **Consumption-GPU-NC8as-T4** profile provides:
   - Up to 8 vCPUs
   - 56 GiB memory
   - 1x NVIDIA T4 GPU (16GB GPU memory)

   - Click **Review + create**

5. **Review and create:**
   - Review all your settings on the summary page
   - Ensure all configurations are correct:
     - Resource group: **my-gpu-demo-group**
     - Container app name: **my-gpu-demo-app**
     - Region: West US 3
     - Image: **mcr.microsoft.com/k8se/gpu-quickstart:latest**
     - GPU enabled with Consumption-GPU-NC8as-T4 profile
     - Ingress enabled on port 80
   - Click **Create**
   - Expect a short pause while Azure validates and starts deployment.

6. **Wait for deployment:**
   - Deployment usually takes 3-5 minutes.
   - You'll be forwarded automatically to a **Deployment is in Progress** screen.
   - Wait for the notification **"Deployment is complete"**
   - Click **Go to resource** to view your deployed container app

7. **Open the application in your browser:**
   - On the Container App overview page:
   - Locate the **Application URL** in the Essentials section at the top right
   - Select the URL to open the app
---

### Task 2 - Test GPU Image Generation Application

**Description:** Now that your GPU-enabled container app is deployed, you'll test its image generation capabilities through the web interface. The application uses AI models running on the GPU to generate images from text prompts.

**Task 2 outcome:** At least one successful image generation request is completed.

1. **Generate your first image:**
   - If the app is not already open, use the **Application URL** from Task 1.
   - **Note:** The app can take 1-2 minutes to load on first start. You can check **Running Status** in **Revisions and Replicas**. Status should show **Activating** or **Running**.

   In the web interface:
   - Enter a text prompt in the input field (e.g., "A futuristic city at sunset with flying cars")
   - Click the **Generate** button
   - Wait for the GPU to process your request and generate the image

   **Note:** The first request may take 60-90 seconds because of GPU cold start. After warmup, image generation is usually 5-15 seconds.

   **What's happening:** The AI model is using the NVIDIA T4 GPU to process your text prompt and generate an image using diffusion models.

2. **Test with different prompts:**
   Try a few prompts to see range and quality:
   - "A serene mountain landscape with a lake reflection"
   - "A robot playing chess in a library"
   - "An astronaut riding a horse on Mars"
   - "A steampunk coffee shop in the clouds"

   Notice how response times improve after the first generation due to GPU warmup and model caching.

---

### Task 3 - Keep One Replica Warm (Reduce Cold Start)

Azure Container Apps serverless GPUs automatically scale your application to zero when idle to save costs. Scaling back out from zero triggers a GPU cold start: provisioning the container, initializing drivers, and loading model assets add cold start time to the first request. To ensure the lab completes without waiting on cold starts, you'll configure a minimum replica of 1 so one GPU instance stays warm during the exercise. We'll discuss cold start improvement strategies later in the lab.

**Task 3 outcome:** One GPU-backed replica remains warm and available.

1. **Open Scale settings:**
   - In the left menu under **Application**, select **Scale**.
   - Set the **Min replicas** to `1`
   - Select **Save as a new revision**.

2. **Confirm running replica:**
   - Go to **Revisions and replicas**.
   - Ensure the latest revision shows **Running** with at least one replica.

**Result:** A single GPU-backed container remains online, eliminating cold start delays for subsequent image generations during the lab.

> [!Note] Setting **Min replicas = 1** keeps a GPU instance allocated at all times which is great for eliminating cold starts, but it incurs continuous GPU charges. This is fine for the lab, but is important to keep in mind when doing your own development.

---

### Task 4 - Monitor GPU Performance

**Description:** Azure Container Apps provides tools to monitor your GPU utilization and performance. In this task, you'll use the console to access your running container and see information about your GPU and test connectivity to external sources.

**Task 4 outcome:** You can access the container shell, run GPU checks, and validate debug-console connectivity tools.

1. **Access the container console via Azure Portal:**
   - Navigate to the Azure Portal: `https://portal.azure.com`
   - Go to your container app: **Resource Groups** → **my-gpu-demo-group** → **my-gpu-demo-app**
   - In the left menu, under **Monitoring**, select **Console**
   - For the console, choose **App Container**
   - If not displayed by default:
     - Select your active **replica** from the dropdown
     - Select your **container** (**my-gpu-demo-container**)
     - Click **Reconnect** if needed

2. **Connect to the container shell:**
   - In the **Choose startup command** dialog, select `/bin/bash`
   - Click **Connect**
   - Wait for the shell prompt to appear. This is the Container App Console, which is useful for troubleshooting your application inside a container.
   - Enter the following command to check NVIDIA GPU status including utilization, memory usage, and running processes: `nvidia-smi`
   - Now enter, `nslookup ollama.com`. Since we're in the container app console, you should see nslookup fail as the container doesn't have access to network access tools.

3. **Check out the Debug Console:**
   The Debug Console helps when you cannot connect to the target container and includes useful networking tools.
   - At the top of the page, choose **Debug** and repeat steps 1 and 2 from Task 4.
   - Now enter, `nslookup ollama.com` – verifies DNS name resolution to Ollama.

---
## Troubleshooting

### Common Issues and Solutions

- **"Workload profile not found" or GPU option not available**
   - **Cause:** GPU workload profiles are not available in your selected region, or GPU quota hasn't been approved.
   - **Solution:**
      1. Test Other supported regions include Sweden Central and Australia East, East US 2, and North Central US.

## Deploy Azure OpenAI

### Success Criteria for This Section

- Reconfigure the existing Container App to run the official Ollama container image with GPU access
- Enable ingress on port `11434` for remote API calls
- Pull multiple models (SmolLM2 1.7B, DeepSeek-R1 14B, GPT-OSS 20B) from inside the container
- Compare model quality with a curated prompt pack
- Exercise Ollama's HTTP API using `curl`, `wget`, and PowerShell commands


## Task 1 - Reconfigure the GPU App to Run Ollama

**Goal:** Swap the container image in `my-gpu-demo` to `ollama/ollama`, expose port `11434`, and keep GPU acceleration enabled.

1. **Open the Container App in Azure Portal**

    - Go to `https://portal.azure.com` and navigate to **Resource groups > my-gpu-demo-group > my-gpu-demo**.

1. **Verify your app is on a T4 GPU workload profile**

    The following steps demonstrate how you can switch between workload profiles (different compute types) in Azure Container Apps.

    - In the navigation blade on the left, select **Overview**. In the **Overview**, click on the **Properties** tab.
    - Confirm the **Workload profile** is set to `t4` with GPU enabled.
    - Select **Change** for the workload profile. 
    - You should see that the GPU box is selected, and the GPU type is `Consumption-GPU-NC8as-T4`.
    - Select **Discard**.

1. **Update the container image**

    - In the navigation blade on the left, select **Application > Containers**.
    - Update **Registry login server** to `docker.io`.
    - Update **Image and tag** to `ollama/ollama:latest`.
    - Ensure that the **CPU cores** are set to `8` and **Memory** is set to `56`.

1. **Set environment variables**

    - Select the **Environment variables** tab.
    - Select **Add** and provide the following environment variables:

        - Set **Name** to `OLLAMA_HOST`, choose **Manual entry**, and enter the value `0.0.0.0`.

    - Click **Save as a new revision**. 
    - This will take a few moments to deploy the new revision. Select the notification bell in the top right to see the status of the ongoing deployment.

1. **Change the port the app receives traffic on**

    - Once the revision has been deployed, select **Networking > Ingress** in the navigation blade on the left.
    - In the **Ingress** section, ensure the checkbox for **Ingress** is selected.
    - Set **Ingress traffic** to **Accepting traffic from anywhere**.
    - Change the **Target port** to `11434`.
    - Select **Save**.

1. **Verify the application is running**

    Once your application's ingress has been updated, verify the application is running.

    - Select **Application > Revisions and replicas**.
    - Under **Running status**, the latest revision you deployed should show as `Activating`. Once it shows as **Running**, your application is ready. If after waiting a few minutes it is still not running, refresh the page.

---

## Task 2 - Pull Ollama Models from the Portal Console

**Goal:** Shell into the running container and pre-load the models you'll test.

**Task 2 outcome:** Ollama is running, required models are pulled, and you can confirm they are installed.

1. **Open the container console**

   - In the Container App blade, select **Monitoring > Console**.
   - Under **Based on revision**, choose the latest revision and newest replica (for example, `gpuquickstart--0000004`).
   - For **Choose startup command**, select `/bin/bash`, then select **Connect**.

2. **Verify Ollama is running**

   Run the following commands in the console:

```bash
ps aux | grep ollama
ollama --version
```

   You should get a response like:

   **ollama --version is x.xx.xx**

3. **Pull the requested models**

   Run the following commands in the console:

```bash
ollama pull smollm2:1.7b
ollama pull deepseek-r1:14b
ollama pull gpt-oss:20b
```

   **Note:** Each download can take several minutes. Keep the console open until all pulls complete.

4. **List installed models**

   Run the following command:

```bash
ollama list
```

   You should see all three models with the **latest** digest.

---

## Task 3 - Compare Model Quality with Prompt Pack

**Goal:** Compare quality, latency, and reasoning behavior across models using a fixed prompt pack.

**Task 3 outcome:** You can clearly describe differences between SmolLM2, DeepSeek-R1, and GPT-OSS for your workload.

Use the console to run these prompts against each model. The goal is to spot differences across model behavior.

```bash
ollama run smollm2:1.7b "Explain the concept of vector databases to a new data engineer in under three sentences."
```
```bash
ollama run deepseek-r1:14b "Write a Python function that generates a haiku using a small in-memory word list."
```
```bash
ollama run gpt-oss:20b "Reason through this riddle: You see me once in a year, twice in a week, and never in a day. What am I?"
```

Pay attention to latency, depth of reasoning, and hallucination risk for each model. Experiment with your own prompts as well!

| Prompt | What to Look For |
| --- | --- |
| Explain the concept of vector databases to a new data engineer in under three sentences. | Clarity + factual accuracy |
| Write a Python function that generates a haiku using a small in-memory word list. | Code correctness + creativity |
| Reason through this riddle: You see me once in a year, twice in a week, and never in a day. What am I? | Chain-of-thought reasoning |

---

## Task 4 - Explore the Ollama REST API

**Goal:** Interact with the Ollama server remotely using typical dev tooling.

**Task 4 outcome:** You can validate model availability and generate responses through the Ollama HTTP API.

### 4.1 Set the container app endpoint as an environment variable

1. **Get your container app URL**
   - In the Azure Portal, select **Overview** in the left-hand navigation blade.
   - Use the copy icon to the right of the **Application URL** to copy the Application URL to the clipboard.

2. **Set the environment variable**
   - Run the following command, replacing `<Your Container App URL>` with the URL you copied:

    ```bash
    export OLLAMA_URL="<Your Container App URL>"
    $env:OLLAMA_URL= "<Your Container App URL>"
    ```

3. **Verify the variable is set**

    ```bash
    echo $OLLAMA_URL
    $env:OLLAMA_URL
    ```

   You should see your container app URL displayed.

### 4.2 List installed models

Run the following command in your terminal:

```bash
curl -s $OLLAMA_URL/api/tags | jq
curl -s $env:OLLAMA_URL/api/tags | jq
```
This will display all models currently available on your Ollama server.

### 4.3 Show model metadata (pick any deployed model)

- **Using curl:**

  ```bash
  curl $OLLAMA_URL/api/show \
  -H "Content-Type: application/json" \
  -d '{"model":"smollm2:1.7b"}'

  curl $env:OLLAMA_URL/api/show -H "Content-Type: application/json" -d '{"model":"smollm2:1.7b"}'
  ```

This returns detailed metadata about the model, including parameters, architecture, and system requirements.

### 4.4 Generate a streamed response

Run the following command to test text generation using curl:

- **Using curl:**

  ```bash
  curl $OLLAMA_URL/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "smollm2:1.7b",
    "prompt": "Explain the concept of vector databases."
  }'

  curl $env:OLLAMA_URL/api/generate -H "Content-Type: application/json" -d '{
    "model": "smollm2:1.7b",
    "prompt": "Explain the concept of vector databases."
  }'
  ```

  You'll see the response stream in real-time as the model generates text.

### 4.5 Return just the response

- By running this command without streaming and parsing the JSON response, you can extract the generated text:

  ```bash
    curl $env:OLLAMA_URL/api/generate -H "Content-Type: application/json" -d '{
        "model": "smollm2:1.7b",
        "prompt": "Explain the concept of vector databases.",
        "stream": false
      }' | jq -r '.response'
  ```

> Tip: For production deployments, you can deploy your inferencing server applications (in this case the Ollama app) an environment integrated with your own virtual networks or behind private endpoints. You can also add managed identity rules for who can access the app. This keeps model traffic on trusted networks and ensures only authorized callers can reach sensitive data.

---

## Persist models and reduce cold starts in production

Serverless scaling in Azure Container Apps is great because it can autoscale to zero. The trade-off is that storage is not persistent by default, so models may need to be re-downloaded after each scale-to-zero event, which increases cold-start time. Below are patterns we see customers use in production to improve startup performance.

1. Add an [Azure Files volume mount](https://learn.microsoft.com/azure/container-apps/storage-mounts-azure-files?tabs=bash) to your Azure Container App.
   - This stores models persistently and avoids re-downloading after scale-to-zero.
   - For an Ollama container image, mount the volume at `/var/lib/ollama`.
2. Use cron scalers or other scalers to pre-warm GPUs ahead of expected traffic spikes.
3. Use Azure Container Registry artifact streaming so containers can start faster by streaming layers on demand.
4. Set a minimum replica count during business hours.
   - Keeping at least one replica running reduces latency from cold starts during peak periods.


## Ollama & Open-Source Models

### Aim
Build a LangChain Agent with Azure Container Apps Dynamic Sessions (Code Interpreter)

### What to Capture in This Section

- Use a pre-provisioned Azure Container Apps **Dynamic Session Pool** for Python code execution in a code interpreter.
- Connect the pool to a **LangChain agent** via the **langchain-azure-dynamic-sessions** package.
- Expose a **FastAPI web API** with endpoints for natural language queries and file analysis.
- Validate with tasks: math calculation, plotting, and CSV summarization.

### LangChain

**LangChain** is a powerful framework for building applications powered by large language models (LLMs). It provides a standardized interface for connecting LLMs with external tools, data sources, and APIs. In this demo, LangChain acts as the orchestration layer that:
- Connects Azure OpenAI's GPT models with the Azure Container Apps Dynamic Sessions code execution environment
- Manages the conversation flow between user queries and code interpreters
- Handles tool selection and parameter passing automatically
- Provides built-in retry logic, error handling, and response parsing

> [!Note] LangChain is the focus for this section of the demo, but the same patterns apply to other agents. Microsoft's newly released [Microsoft Agent Framework](https://learn.microsoft.com/agent-framework/overview/agent-framework-overview) is a great alternative, and you'll experiment with [Goose](https://github.com/block/goose) later in the demo as well.

### Code Interpreters

**Code interpreters** are secure, isolated environments that allow AI agents to write and execute code dynamically in response to user queries. Unlike traditional chatbots that can only generate text responses, code interpreters enable AI systems to perform actual computations, analyze data, create visualizations, and manipulate files in real-time. This capability transforms AI agents from conversational tools into powerful problem-solving assistants that can handle complex mathematical calculations, data analysis tasks, and generate visual outputs like charts and graphs. Azure Container Apps Dynamic Sessions provides enterprise-grade code interpreter functionality with built-in security, scalability, and integration with popular AI frameworks like LangChain.

By using LangChain with code interpreters, you can build sophisticated AI agents that reason about when to execute code, what code to write, and how to interpret the results-all with minimal custom code.

### Task 1 - Setup

Open VS Code and authenticate with your Azure subscription using the Azure CLI.

```bash
az login
```
- Follow the instructions for signing in.  

Confirm you're using the correct Azure subscription

```bash
az account show
```

**Expected output:** You should see your subscription ID, name, and tenant information. Verify this matches the subscription you want to use

## MCP Shell Integration

### What to Capture in This Section

- MCP server/tool configuration and startup command.
- Shell integration steps and test command examples.
- Verification results showing tool calls are working.


## Goose AI Agent

### What to Capture in This Section

- Agent setup steps and model configuration.
- Tool permissions and safety boundaries.
- Example prompt flows used for validation.


## Azure Container Apps Dynamic Sessions

### What to Capture in This Section

- Session Pool configuration choices.
- Security model and RBAC decisions.
- Test run evidence (successful isolated execution).


## Build LangChain Application

### What to Capture in This Section

- App architecture (chains/agents/tools/memory).
- Environment variables required by the app runtime.
- Local run steps and expected output.
- Known limitations and next improvements.


## Deploy and Test

### What to Capture in This Section

- Deployment command sequence.
- Post-deploy smoke tests.
- Validation checklist (health, logs, API responses, UI behavior).
- Rollback or mitigation steps if validation fails.


## 🐛 Troubleshooting

Use this section as your first stop for common setup and runtime issues before re-running tasks.

### Common Issues

**Issue**: Line ending errors (`/usr/bin/env: 'bash\r': No such file or directory`)
```bash
# Fix with dos2unix
dos2unix concat_lab_segments.sh
# Or with sed
sed -i 's/\r$//' concat_lab_segments.sh
```

**Issue**: Azure OpenAI quota error (`SpecialFeatureOrQuotaIdRequired`)
- **Solution**: Your subscription needs Azure OpenAI access approval
- Apply at: https://aka.ms/oai/access

**Issue**: Model deployment error (`InvalidResourceProperties`)
- **Solution**: Use GPT-3.5 Turbo version `0125` in `eastus` region
- Verified working configuration in lab

**Issue**: Python venv not found (`python3.12-venv not available`)
```bash
# Install generic Python venv
sudo apt install python3-venv python3-pip
```

**Issue**: Role assignment fails (`BadRequest` or `Forbidden`)
- **Solution**: Verify you're using the Pool ID (resource path), not Pool Management Endpoint (URL)
- Use: `/subscriptions/.../providers/Microsoft.App/sessionPools/...`
- Not: `https://...dynamicsessions.io/...`

### Getting Help

- Check Azure resource status in Azure Portal
- Review application logs with `az containerapp logs`
- Verify environment variables are set correctly
- Ensure all resource providers are registered

### Escalation Path

1. Re-run the exact failed command with verbose output where available.
2. Capture error text, timestamp, resource name, and region.
3. Check Azure Portal activity logs and relevant resource logs.
4. Validate RBAC scopes and environment variables.
5. If blocked, open an issue in your repo with reproduction steps and logs.

## Additional Resources

Use these links when you want deeper implementation detail beyond the lab flow.

### Azure Documentation

- [Azure Container Apps Overview](https://learn.microsoft.com/azure/container-apps/overview)
- [Dynamic Sessions Documentation](https://learn.microsoft.com/azure/container-apps/sessions)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/cognitive-services/openai/)
- [Azure RBAC](https://learn.microsoft.com/azure/role-based-access-control/)

### Sample Code & Tutorials

- [Container Apps Dynamic Sessions Samples](https://github.com/Azure-Samples/container-apps-dynamic-sessions-samples)
- [LangChain Python Documentation](https://python.langchain.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

### Tools & SDKs

- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [Azure SDK for Python](https://learn.microsoft.com/python/azure/)
- [LangChain Azure Integration](https://python.langchain.com/docs/integrations/platforms/microsoft)
- - [Gpt-oss on Azure Container Apps](https://techcommunity.microsoft.com/blog/appsonazureblog/open-ais-gpt-oss-models-on-azure-container-apps-serverless-gpus/4440836)
- [Deepseek-r1 on Azure Container Apps](https://techcommunity.microsoft.com/blog/appsonazureblog/deepseek-r1-on-azure-container-apps-serverless-gpus/4371463)
