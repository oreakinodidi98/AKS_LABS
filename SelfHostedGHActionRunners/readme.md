
# Self-Hosted GitHub Actions Runners on Kubernetes

> Stop paying per-minute for private repo CI — run your own GitHub Actions runners inside your cluster, scale to zero when idle, and scale to infinity when you need them.

---

## Prerequisites

| Requirement | Details |
|---|---|
| **AKS Cluster** | A running Kubernetes cluster with `kubectl` configured (`az aks get-credentials`) |
| **Helm 3** | Required to install the ARC controller and runner scale sets |
| **GitHub PAT** | A **fine-grained personal access token** — see [Step 3](#3-create-a-github-personal-access-token) for required permissions |
| **Namespace** | `arc-systems` for the controller; a separate namespace for your runner scale set |

---

## Why GitHub Actions

GitHub Actions is the **native CI/CD platform** for GitHub — it's where most teams already live. Community support is massive, the marketplace has thousands of reusable actions, and it's **free for public repositories**.

The catch — **private repos burn through minutes fast**. Once you exceed the free tier, you're paying per-minute for hosted runners. That adds up quickly for active teams.

---

## The Problem with Hosted Runners

You *can* self-host a runner on a VM — GitHub even gives you the exact steps under **Settings → Actions → Runners → New self-hosted runner**. Works great for a single machine.

But a dedicated VM sitting idle between builds is still **money on fire**. You're paying for compute whether it's running jobs or not.

---

## The Fix — Actions Runner Controller (ARC)

The better approach — run GitHub Actions runners **inside Kubernetes** using **ARC** (Actions Runner Controller). It's an official GitHub project that lets you scale runners dynamically inside your cluster. Jobs spin up pods, pods die when done. No idle compute, no per-minute billing.

> **Docs:** [Actions Runner Controller — GitHub](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller)

---

## What This Guide Covers

- **Why self-hosted** — cost, control, and scale
- **Installing ARC** — Helm chart deployment on AKS
- **GitHub PAT setup** — fine-grained token with the right permissions
- **Runner scale set** — connecting your cluster to a specific repo

---

## Setup

### 1. Create the Kubernetes Cluster

If you don't already have one, stand up an AKS cluster. Any existing cluster works — ARC runs alongside your other workloads.

### 2. Deploy the ARC Controller

Install the **ARC Helm chart** into the `arc-systems` namespace:

```bash
# Bash / Linux / macOS
NAMESPACE="arc-systems"

helm install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

```powershell
# PowerShell
helm install arc --namespace "arc-systems" --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

This deploys the **controller** — the component that watches for GitHub webhook events and spins up runner pods in response.

### 3. Create a GitHub Personal Access Token

Go to **GitHub → Settings → Developer settings → Fine-grained personal access tokens → Generate new token**.

Set the following **repository permissions**:

| Permission | Access |
|---|---|
| **Administration** | Read and write |
| **Metadata** | Read-only |

> **Important:** Scope the token to the **specific repository** (or organization) where you want runners to pick up jobs. Don't use a classic token — fine-grained gives you least-privilege control.

### 4. Deploy the Runner Scale Set

This connects your cluster to a **specific GitHub repo** — any workflow in that repo with `runs-on: arc-runner-set` will pick up a runner pod from your cluster.

Set the following variables, then install:

```bash
# Bash / Linux / macOS
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/<your_enterprise/org/repo>"
GITHUB_PAT="<PAT>"

helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

```powershell
# PowerShell
$INSTALLATION_NAME = "arc-runner-set"
$NAMESPACE = "arc-runners"
$GITHUB_CONFIG_URL = "https://github.com/<your_enterprise/org/repo>"
$GITHUB_PAT = "<PAT>"

helm install $INSTALLATION_NAME --namespace $NAMESPACE --create-namespace --set githubConfigUrl=$GITHUB_CONFIG_URL --set githubConfigSecret.github_token=$GITHUB_PAT oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

> **Replace** `<your_enterprise/org/repo>` with your actual repo path (e.g. `oreakinodidi98/Demo_AKS_Modernization`) and `<PAT>` with the token from Step 3.

### 5. Verify the Installation

Confirm both Helm releases are deployed:

```bash
helm list -A
```

Check that the **controller manager** pod is running:

```bash
kubectl get pods -n arc-systems
```

---

## Test It — Trigger a Workflow

Create a workflow file in your repo (e.g. `.github/workflows/arc-demo.yml`) that targets **your runner scale set name**:

```yaml
name: Actions Runner Controller Demo
on:
  workflow_dispatch:

jobs:
  Explore-GitHub-Actions:
    # Must match the INSTALLATION_NAME from Step 4
    runs-on: arc-runner-set
    steps:
      - run: echo "🎉 This job uses runner scale set runners!"
```

Then **manually trigger** the workflow — go to **Actions → Actions Runner Controller Demo → Run workflow**.

> **Docs:** [Manually running a workflow — GitHub](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow)

Watch the runner pods spin up in real time:

```bash
kubectl get pods -n arc-runners -w
```

You should see a pod appear when the job starts and disappear once it completes — that's ARC doing its thing.