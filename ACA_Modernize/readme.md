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
  - [Dynamic Sessions](#dynamic-sessions)
    - [Validated Runbook (Recommended for This Repo)](#validated-runbook-recommended-for-this-repo)
      - [What to Verify Before Running](#what-to-verify-before-running)
      - [Required Environment Variables for This Sample](#required-environment-variables-for-this-sample)
      - [Verified Setup Steps (Accurate Path)](#verified-setup-steps-accurate-path)
      - [Run and Validate (Current Sample Behavior)](#run-and-validate-current-sample-behavior)
      - [Expected Output Reality Check](#expected-output-reality-check)
    - [Task 1 - Setup](#task-1---setup)
      - [Understanding the **.env** file](#understanding-the-env-file)
      - [Populating the **.env** file](#populating-the-env-file)
      - [Step 4: Review the Python virtual environment](#step-4-review-the-python-virtual-environment)
      - [Step 5: Activate the virtual environment](#step-5-activate-the-virtual-environment)
      - [Step 6: Review Installed application dependencies](#step-6-review-installed-application-dependencies)
    - [Task 4 - Run the Application](#task-4---run-the-application)
      - [Understanding **main.py**](#understanding-mainpy)
      - [Step 7: Run the LangChain agent](#step-7-run-the-langchain-agent)
    - [Task 5 - Validate Agent Behavior](#task-5---validate-agent-behavior)
      - [1. **Validate baseline run:**](#1-validate-baseline-run)
      - [2. **Validate authentication path:**](#2-validate-authentication-path)
      - [3. **Validate custom prompt behavior (optional):**](#3-validate-custom-prompt-behavior-optional)
  - [Dynamic Sessions End to end Setup (Optional)](#dynamic-sessions-end-to-end-setup-optional)
    - [Part 1: Infrastructure Setup](#part-1-infrastructure-setup)
      - [Step 1: Authenticate and Set Environment Variables](#step-1-authenticate-and-set-environment-variables)
      - [Step 2: Create Resource Group](#step-2-create-resource-group)
      - [Step 3: Create Dynamic Session Pool](#step-3-create-dynamic-session-pool)
      - [Step 4: Assign Session Pool Roles](#step-4-assign-session-pool-roles)
      - [Step 5: Create Azure OpenAI Resource](#step-5-create-azure-openai-resource)
      - [Step 6: Deploy Model](#step-6-deploy-model)
      - [Step 7: Assign Azure OpenAI Role](#step-7-assign-azure-openai-role)
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
- Run a **LangChain agent script** that handles natural language tasks and code execution.
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

## Dynamic Sessions

Use Dynamic Sessions to run code in isolated, short-lived sandboxes while keeping your local machine safe.

Why this matters:

- You get real execution power (Python and Bash) without running untrusted code on your host.
- You can do file upload/download in the sandbox and move results back locally.
- You can combine shell + Python tools in a single agent workflow.

Core capabilities:

1. Python REPL execution.
2. Bash command execution.
3. Remote file upload/download.
4. Per-session isolation (clean boundary from host environment).

### Validated Runbook (Recommended for This Repo)

Use this runbook first. It is aligned to the current files in this repository and keeps your original lab notes below for reference.

> [!Important]
> In the current repository state, `container-apps-dynamic-sessions-samples/langchain-python-webapi/main.py` runs as a LangChain script (CLI-style) and does **not** expose FastAPI endpoints such as `/chat` or `/health`.
>
> That means:
> - Use `python main.py` to run the sample.
> - Do not expect `uvicorn` startup output in this sample.
> - Do not expect `http://localhost:8000/docs` in this sample.

#### What to Verify Before Running

1. You are signed in with Azure CLI and using the correct subscription.
2. Dynamic Session Pool endpoints are available.
3. The `.env` file contains required keys used by `main.py`.
4. Your Python virtual environment is active.

#### Required Environment Variables for This Sample

These variable names are what the current `main.py` requires:

- `LLM_MODEL_DEPLOYMENT_NAME_CHATGPT`
- `FOUNDRY_API_KEY`
- `FOUNDRY_ENDPOINT`
- `SESSIONPOOL_MANAGEMENT_ENDPOINT_SHELL`
- `SESSIONPOOL_MANAGEMENT_ENDPOINT_PYTHON`
- `SESSIONPOOL_MCP_ENDPOINT_SHELL`
- `SESSIONPOOL_MCP_ENDPOINT_PYTHON`

> [!Tip]
> Keep your original variables too if you need them for other sections. For this script specifically, the list above is what is validated in code.

#### Verified Setup Steps (Accurate Path)

1. Sign in and confirm context:

   ```bash
   az login
   az account show
   ```

   Expected result:
   - `az login` completes successfully and opens/authenticates your account.
   - `az account show` returns your active subscription JSON.

2. Go to the sample folder:

   ```bash
   cd container-apps-dynamic-sessions-samples/langchain-python-webapi
   ```

3. Create your env file from the sample template:

   ```bash
   cp .env.sample .env
   ```

4. Populate `.env` with real values for all required variables listed above.

5. Activate virtual environment:

   ```bash
   source venv/bin/activate
   ```

   Expected result:
   - Your shell prompt shows `(venv)`.

6. (Optional) Install dependencies if needed:

   ```bash
   pip install -r requirements.txt
   ```

#### Run and Validate (Current Sample Behavior)

1. Run the app script:

   ```bash
   python main.py
   ```

   Expected result:
   - The script runs an agent flow and prints streamed/pretty-printed messages in the terminal.
   - You should see activity related to tool use (Python/Bash session tools), not HTTP server startup logs.

2. If authentication fails:
   - Re-run `az login`.
   - Verify subscription with `az account show`.
   - Re-run `python main.py`.

3. If env validation fails:
   - You will see a runtime error like `Missing required environment variable: <NAME>`.
   - Add the missing variable to `.env` and retry.

#### Expected Output Reality Check

For this sample as currently committed:

- Valid expected output:
  - Terminal prints from agent execution.
  - Possible Azure token or missing-env errors if configuration is incomplete.

- Not expected in this sample:
  - `INFO: Uvicorn running on http://127.0.0.1:8000`
  - Swagger UI at `http://localhost:8000/docs`
  - Curl calls to `/chat` or `/health`

---

### Task 1 - Setup

> [!Note]
> Original notes below are preserved as requested. For the most accurate step-by-step flow in this repo state, use the **Validated Runbook (Recommended for This Repo)** section above.

Run Terraform file in infra to set up enviroment
1. Provision Dynamic Session pools with Terraform (Python and Shell pools).
2. Activate virtual environment:
   - `agent_env\Scripts\activate`
3. Ensure environment variables are configured:
   - `SESSIONPOOL_MANAGEMENT_ENDPOINT_PYTHON`
   - `SESSIONPOOL_MANAGEMENT_ENDPOINT_SHELL`

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

Change to the directory containing the LangChain Python web API sample code.

```bash
cd container-apps-dynamic-sessions-samples/langchain-python-webapi
```

**What this does:**  This directory contains:
- **main.py** - The LangChain agent runner script with Azure Dynamic Sessions tools
- **.env.sample** - Sample configuration file with Azure resource endpoints and credentials
- **requirements.txt** - Python package dependencies

**Description:** Before running the application, let's understand the key resources that make it work.

---

#### Understanding the **.env** file

The **.env** file contains all the configuration settings needed to connect your application to Azure services. It stores:

- **SESSIONPOOL_MANAGEMENT_ENDPOINT_PYTHON** - The management endpoint for your Azure Container Apps Dynamic Session Pool
- **FOUNDRY_ENDPOINT** - The endpoint URL for your Azure OpenAI service
- **LLM_MODEL_DEPLOYMENT_NAME_CHATGPT** - The name of your deployed GPT model (e.g., **gpt-4o-mini**)
- **FOUNDRY_API_KEY** - The API key to use for Azure OpenAI calls

**Why this is valuable:** 
- Separates configuration from code, making it easy to switch between development, staging, and production environments
- Keeps sensitive information (endpoints and identifiers) out of source code
- Follows the "twelve-factor app" methodology for cloud-native applications
- The **.env** file has been pre-configured with your lab environment's resource endpoints

**Security note:** In production environments, you would use Azure Key Vault or managed identities instead of storing credentials in files.

---

#### Populating the **.env** file

Create a new **.env** file using the VS Code wsl terminal:

 ```bash
 cd container-apps-dynamic-sessions-samples/langchain-python-webapi
 cp .env.sample .env
```

And open the new .env file in the explorer on the left.

Locate and copy/paste the following variables into your .env file:

1. **Pool Management Endpoints**
- In the Azure Portal, search for `Container App Session Pool` and click on **Container App Session Pool** .  Open the Container App Session Pool resource displayed, then copy the Pool Management Endpoint displayed on the top right and paste it into the .env file.  

```bash
SESSIONPOOL_MANAGEMENT_ENDPOINT_PYTHON=<Python Pool Management Endpoint>
SESSIONPOOL_MANAGEMENT_ENDPOINT_SHELL=<Shell Pool Management Endpoint>
SESSIONPOOL_MCP_ENDPOINT_PYTHON=<Python Pool MCP Endpoint>
SESSIONPOOL_MCP_ENDPOINT_SHELL=<Shell Pool MCP Endpoint>
```


2. **OpenAI Endpoint and Key**
- In the Azure Portal, search for `Azure OpenAI` and click on **Azure OpenAI** .  Open the Azure OpenAI resource displayed. On the left, go to **Resource Management > Keys and Endpoint**  and copy/paste the following values:

```bash
FOUNDRY_ENDPOINT=<Endpoint>
FOUNDRY_API_KEY=<KEY 1>
```
3. **Model Name**

-From Keys and Endpoint, click on **Overview** on the top left then click on **Go to Azure AI Foundry Portal** towards the top on the left.   
-If you are asked to log in again, follow the same steps from the previous login process.  
-Once in the foundry, click on **Deployments** on the left, and copy and paste the **Model Name** into the .env file.

```bash
LLM_MODEL_DEPLOYMENT_NAME_CHATGPT=<Model Deployment Name>
```

- Once complete, you should have all required values in your new .env file.  
- save the .env file

```bash
FOUNDRY_ENDPOINT=<Endpoint>
FOUNDRY_API_KEY=<KEY 1>
LLM_MODEL_DEPLOYMENT_NAME_CHATGPT=<Model Deployment Name>
SESSIONPOOL_MANAGEMENT_ENDPOINT_PYTHON=<Python Pool Management Endpoint>
SESSIONPOOL_MANAGEMENT_ENDPOINT_SHELL=<Shell Pool Management Endpoint>
SESSIONPOOL_MCP_ENDPOINT_PYTHON=<Python Pool MCP Endpoint>
SESSIONPOOL_MCP_ENDPOINT_SHELL=<Shell Pool MCP Endpoint>
```
**Security note:** In production environments, you would use Azure Key Vault or managed identities instead of storing credentials in files.

---

#### Step 4: Review the Python virtual environment

An isolated Python environment has already been created and populated with application dependencies.

**What this is:** A new directory called **venv** contains a complete Python environment. This keeps the lab dependencies separate from your system Python installation, preventing version conflicts.

**Why this is valuable:** Virtual environments are a Python best practice that ensure reproducible builds and prevent dependency conflicts between different projects.

---

#### Step 5: Activate the virtual environment

Activate the virtual environment so that Python commands use the isolated environment.

Make sure that you are in the application directory:

**../container-apps-dynamic-sessions-samples/langchain-python-webapi**

```bash
source venv/bin/activate
```

**What this does:** Modifies your shell's PATH to prioritize the virtual environment's Python interpreter and packages. You'll see **(venv)** appear at the beginning of your command prompt.

**Note:** You'll need to run this command again if you open a new terminal session.

---

#### Step 6: Review Installed application dependencies

the command **pip install -r requirements.txt** preinstalled all required Python packages from the requirements file.

**What this did:** Installs the following key packages:
- **langchain** & **langgraph** - Core agent orchestration
- **langchain-openai** - Azure OpenAI-compatible chat model integration
- **langchain-azure-dynamic-sessions** - Python and Bash tool execution in Azure Dynamic Sessions
- **langchain-mcp-adapters** - MCP integration helpers
- **langchain_azure_cosmosdb** - Optional Cosmos DB integration support
- **markdownify** - Content conversion helper

**Note:** Dependencies are preinstalled, as it typically takes 10 minutes or more to download and install all dependencies.


### Task 4 - Run the Application

**Description:** In this task, you'll run the LangChain agent script and confirm it can call Dynamic Sessions tools.

---

#### Understanding **main.py**

The **main.py** file is the heart of your application. It:

1. **Imports and initializes LangChain components:**
   - Creates an Azure OpenAI chat model instance
   - Initializes Azure Dynamic Sessions tools for Python and Bash execution
   - Configures a LangChain agent with those tools

2. **Validates required environment variables:**
   - Fails fast with a clear error if a required variable is missing
   - Uses Azure CLI credentials to obtain access tokens for Dynamic Sessions

3. **Manages the agent execution flow:**
   - Uses a preset user question in the script
   - Determines if code execution is needed
   - Executes Python and/or Bash commands in Azure Dynamic Sessions
   - Returns results back to the user

**Why this is valuable:**
- Demonstrates how to build production-ready AI agents with proper error handling
- Shows best practices for integrating Azure services with LangChain
- Provides a reusable pattern for building code-execution-powered AI applications
- Provides a terminal-first execution loop that is easy to debug during labs

---

#### Step 7: Run the LangChain agent

Run the script directly:

```bash
python main.py
```

**What this does:**
- Loads `.env` and validates required configuration
- Creates the model + tool-enabled agent
- Sends the built-in prompt and streams agent output in the terminal

**Expected output:** You should see streamed agent/tool messages in the terminal. If configuration is incomplete, you'll see a clear error (for example, missing environment variable or Azure authentication failure).

Example error patterns you might see while setting up:

```bash
RuntimeError: Missing required environment variable: <NAME>
RuntimeError: Failed to acquire Azure token for Dynamic Sessions
```

**Note:** Keep this terminal open while the run completes so you can inspect tool calls and generated outputs.

---

### Task 5 - Validate Agent Behavior

**Description:** This task verifies that your LangChain agent can successfully execute code in Azure Dynamic Sessions.

#### 1. **Validate baseline run:**

- Run:

```bash
python main.py
```

- Confirm the agent returns a complete response and no missing-env errors.

#### 2. **Validate authentication path:**

- If token acquisition fails, run:

```bash
az login
az account show
python main.py
```

- Expected result: run succeeds after login and prints agent output.

#### 3. **Validate custom prompt behavior (optional):**

- In `main.py`, update the `question` variable to one of these prompts and rerun:

1. Math calculation test:

```text
Calculate the mean of 1,2,3,100 using Python.
```

Expected result: approximately `26.5`.

2. Data visualization test:

```text
Plot sin(x) from -1 to 1 and report the peak value.
```

Expected result: peak value approximately `0.8415`.

3. Bash capability test:

```text
Create a hello world flask app in a new remote environment, then send a request to show it works.
```

Expected result: the agent uses shell + Python tooling to scaffold and verify the app within the session environment.

---

## Dynamic Sessions End to end Setup (Optional)

- This section walks you through the complete infrastructure setup, including creating the resource group, session pool, Azure OpenAI service, and all necessary role assignments.

---

### Part 1: Infrastructure Setup

#### Step 1: Authenticate and Set Environment Variables

Sign in to Azure and configure your environment variables for the deployment.

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
```

#### Step 2: Create Resource Group

Create a resource group to contain all lab resources.

```powershell
az group create --name $env:RG --location $env:LOCATION
```

#### Step 3: Create Dynamic Session Pool

Create a Dynamic Session Pool with Python runtime for secure, isolated code execution.

```powershell
az containerapp sessionpool create `
   --name $env:POOL `
   --resource-group $env:RG `
   --location $env:LOCATION `
   --container-type PythonLTS `
   --max-sessions 50 `
   --lifecycle-type Timed `
   --cooldown-period 300 `
   --network-status EgressEnabled
```

**What this does:**
- Creates an isolated Python runtime pool (`PythonLTS`) for remote code execution sessions.
- `--max-sessions 50`: Supports up to 50 concurrent code execution sessions.
- `--cooldown-period 300`: Sessions remain available for 5 minutes after use.
- `--network-status EgressEnabled`: Allows outbound internet access from session containers. Use `EgressDisabled` if you want stricter outbound network isolation.

Get the pool management endpoint and resource ID for later configuration and RBAC.

```powershell
$poolInfo = az containerapp sessionpool show --name $env:POOL --resource-group $env:RG --query "{endpoint: managementEndpoint, resourceId: id}" -o json | ConvertFrom-Json
$env:POOL_ENDPOINT = $poolInfo.endpoint
$env:POOL_RESOURCE_ID = $poolInfo.resourceId
```

#### Step 4: Assign Session Pool Roles

Grant your signed-in identity permissions on the session pool.

```powershell
az role assignment create `
   --assignee-object-id $env:USER_OBJECT_ID `
   --role "Azure Container Apps Session Executor" `
   --scope $env:POOL_RESOURCE_ID

az role assignment create `
   --assignee-object-id $env:USER_OBJECT_ID `
   --role "Contributor" `
   --scope $env:POOL_RESOURCE_ID
```

**Roles explained:**
- **Azure Container Apps Session Executor**: Allows creating and executing code in sessions.
- **Contributor**: Allows managing the session pool resource.

#### Step 5: Create Azure OpenAI Resource

Provision Azure OpenAI in the same resource group.

```powershell
az cognitiveservices account create `
   --name $env:OPENAI_NAME `
   --resource-group $env:RG `
   --kind OpenAI `
   --sku S0 `
   --location $env:LOCATION `
   --custom-domain $env:OPENAI_DOMAIN
```

#### Step 6: Deploy Model

Create the model deployment used by the sample application.

```powershell
az cognitiveservices account deployment create `
   --name $env:OPENAI_NAME `
   --resource-group $env:RG `
   --deployment-name $env:DEPLOYMENT_NAME `
   --model-name gpt-5.4 `
   --model-version "1106" `
   --model-format OpenAI `
   --sku-capacity "30" `
   --sku-name "Standard"
```

Retrieve endpoint and resource ID:

```powershell
$env:OPENAI_ENDPOINT = az cognitiveservices account show --name $env:OPENAI_NAME --resource-group $env:RG --query "properties.endpoint" -o tsv
$env:OPENAI_ID = az cognitiveservices account show --name $env:OPENAI_NAME --resource-group $env:RG --query "id" -o tsv
```

#### Step 7: Assign Azure OpenAI Role

Grant your identity OpenAI usage permissions via Azure AD.

```powershell
az role assignment create `
   --assignee-object-id $env:USER_OBJECT_ID `
   --role "Cognitive Services OpenAI User" `
   --scope $env:OPENAI_ID
```

**Why this is needed:** This role allows your identity to make API calls to Azure OpenAI without requiring API keys (uses Azure AD authentication instead).


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
