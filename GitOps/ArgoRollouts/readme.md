# Argo Rollouts

Progressive delivery controller for Kubernetes — similar to a standard Deployment but with built-in blue-green and canary strategies.

## Table of Contents

- [Argo Rollouts](#argo-rollouts)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [CLI Plugin (Windows)](#cli-plugin-windows)
  - [Dashboard](#dashboard)
  - [Common Commands](#common-commands)
  - [Blue-Green Walkthrough](#blue-green-walkthrough)
    - [Create the Rollout](#create-the-rollout)
    - [Deploy a New Version](#deploy-a-new-version)
    - [Promote](#promote)
    - [Rollback](#rollback)
  - [Cleanup](#cleanup)

## Installation

Create a dedicated namespace and install Argo Rollouts:

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.8.3/install.yaml
kubectl get pods -n argo-rollouts
```

> **Tip**: Set a PowerShell alias to save keystrokes: `Set-Alias -Name k -Value kubectl`

## CLI Plugin (Windows)

Install the Argo Rollouts kubectl plugin from the [latest release](https://github.com/argoproj/argo-rollouts/releases/latest/):

```powershell
# Download the Windows binary
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-windows-amd64

# Rename and move to a directory in your PATH
Move-Item kubectl-argo-rollouts-windows-amd64 "$env:USERPROFILE\kubectl-argo-rollouts.exe"

# Verify installation
kubectl argo rollouts version
```

> **Note**: Make sure `$env:USERPROFILE` (or wherever you place the `.exe`) is in your `PATH`. Alternatively, move it to a directory already in your PATH like `C:\Windows\System32\`.

## Dashboard

```bash
kubectl argo rollouts dashboard
```

## Common Commands

```bash
kubectl get rollout
kubectl argo rollouts get rollout
kubectl argo rollouts promote
kubectl argo rollouts undo
```

## Blue-Green Walkthrough

### Create the Rollout

```bash
kubectl apply -f argorollouts/rollout.yaml
```

Check status — make sure both service pods are available:

```bash
kubectl argo rollouts get rollout rollout-bluegreen
```

### Deploy a New Version

```bash
kubectl apply -f argorollouts/rolloutv2.yaml
```

This changes the image from `argoproj/rollouts-demo:blue` to `argoproj/rollouts-demo:green`.

The rollout status moves from **Healthy** to **Paused**, indicating the rollout is in progress and waiting for further action.

Because we set `autoPromotionEnabled: false`, the rollout pauses here. If set to `true`, it skips the pausing phase and promotes directly.

### Promote

```bash
kubectl argo rollouts promote rollout-bluegreen
```

The new revision changes from **preview** to **stable, active** — indicating this revision is now live. The previous revision will show **delay** and eventually move into **ScaledDown** status.

Verify the active service is pointing to the new revision:

```bash
kubectl describe svc rollout-bluegreen-active
```

### Rollback

```bash
kubectl argo rollouts undo rollout-bluegreen
kubectl argo rollouts get ro rollout-bluegreen
```

> **Note**: Undo alone does not set the blue image as active. The rollout will be in a pausing phase waiting for promotion.

Promote to complete the rollback:

```bash
kubectl argo rollouts promote rollout-bluegreen
```

## Cleanup

```bash
kubectl delete rollout rollout-bluegreen
kubectl delete svc rollout-bluegreen-active
```