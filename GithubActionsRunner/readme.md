---
title: GitHub Actions Runner on AKS Automatic
description: Deploy GitHub Actions Runner Controller on AKS Automatic for self-hosted workflow jobs
ms.date: 2026-09-30
ms.topic: tutorial
---

## Overview

In this demo, I use GitHub Actions Runner Controller (ARC) to run self-hosted
GitHub Actions runners on Azure Kubernetes Service (AKS) Automatic.

The workflow maps `runs-on` to an ARC runner scale set. When a job enters the
queue, ARC creates an ephemeral runner pod on AKS Automatic. The runner connects
to GitHub, completes the job, and is removed when the job finishes.

## Why I use ARC with AKS Automatic

AKS Automatic provides a production-ready foundation for ARC, including managed
node pools, built-in monitoring, scaling, and security defaults aligned with AKS
best practices.

This combination provides:

* GitHub-native CI jobs on Kubernetes-based ephemeral runners
* Runner scale sets that expand and contract with workflow demand
* A pod readiness service-level agreement (SLA), which is useful when CI/CD jobs
  depend on fast pod startup
* Secure-by-default AKS settings and production-focused safeguards
* Access to private endpoints, internal services, and restricted dependencies
  from within an Azure virtual network

Build jobs can reach private resources without exposing those resources to the
public internet.

## Prerequisites

Sign in to Azure and GitHub:

```powershell
az login
gh auth login
```

Install or update the AKS preview extension:

```powershell
az extension add --name aks-preview --upgrade
```

Confirm that the Kubernetes, Azure authentication, Helm, and GitHub CLIs are
available locally:

```powershell
kubectl version --client
kubelogin --version
helm version
gh auth status
```

## Deploy the demo

Run the setup script from this directory:

```powershell
.\setup.ps1
```
