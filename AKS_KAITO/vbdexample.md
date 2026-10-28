# Running AI & LLM Models on AKS: The KAITO Blueprint

> Leading organizations aren't just running Kubernetes — they're running intelligence *on* Kubernetes. KAITO is how you get there.

---

## Section 1: The Case for AI on Kubernetes

---

### Slide 1: The AI Infrastructure Crisis

**Hook:** Every enterprise wants to run AI models. Almost none of them have the GPU infrastructure expertise to do it well.

**Key Points:**

- **The Demand Explosion** — AI/LLM workloads are no longer experimental. Enterprises need inference endpoints for customer-facing applications, internal copilots, RAG pipelines, and domain-specific fine-tuned models. The question has shifted from "should we run LLMs?" to "how do we run them reliably, securely, and cost-effectively?"
- **The GPU Complexity Tax** — Running an LLM on Kubernetes isn't "just deploy a container." You need: GPU-enabled node pools with the right VM SKU, NVIDIA GPU drivers installed and configured, the NVIDIA device plugin exposing `nvidia.com/gpu` as an allocatable resource, Node Feature Discovery (NFD) and GPU Feature Discovery (GFD) labeling nodes correctly, vLLM or another inference engine configured for the model architecture, and a Kubernetes service exposing an OpenAI-compatible API. That's six layers of infrastructure before you send your first prompt.
- **The Expertise Gap** — Most platform teams are Kubernetes experts. Very few are *GPU Kubernetes* experts. The intersection of NVIDIA driver versions, CUDA compatibility, GPU memory management, vLLM configuration, and Kubernetes scheduling is a specialized domain that takes months to learn.
- **The Cost Pressure** — A single `Standard_NC24ads_A100_v4` GPU node costs ~$3.67/hour on-demand. A 3-node GPU cluster for multi-model serving is ~$8,000/month. Mistakes in provisioning, idle GPU time, and over-provisioning are expensive — and invisible without proper monitoring.

**Visual Idea:** A "complexity iceberg" — above the waterline: "Deploy an LLM" (simple, one line). Below the waterline (much larger): "GPU drivers, device plugins, NFD, GFD, vLLM, scheduling, taints, tolerations, autoscaling, monitoring" — with the platform engineer's frustration meter redlining.

---

### Slide 2: Enter KAITO — The Kubernetes AI Toolchain Operator

**Concept:** KAITO eliminates the GPU complexity tax. You declare *what model you want*. KAITO handles *everything else*.

**Key Points:**

- **What KAITO Does — The Full Stack:**
  - **Provisions GPU node pools** — requests the right VM SKU and spins up GPU-enabled nodes
  - **Installs NVIDIA GPU drivers** — handles driver lifecycle automatically
  - **Installs the device plugin** — exposes `nvidia.com/gpu` as an allocatable Kubernetes resource
  - **Runs the model on GPU VMs using vLLM** — high-throughput, OpenAI-compatible inference engine
  - **Exposes an inference endpoint** — Kubernetes Service with `/v1/chat/completions`, `/v1/completions`, `/v1/models`, and `/v1/responses` endpoints
  - **Scales to meet demand** — integrates with cluster autoscaler and Node Auto-Provisioning (Karpenter)
  - **Monitors GPU usage** — Prometheus metrics at `/metrics` for utilization, throughput, and latency
  - **Supports RAG workloads** — RAG engine based on the Haystack framework

- **CNCF Sandbox Project** — KAITO is a CNCF Sandbox project. It's not a proprietary Azure lock-in — it's community-governed, open-source Kubernetes-native AI infrastructure.
- **The Workspace CRD — Your Single Interface** — You write a `Workspace` custom resource. You specify the model name, the GPU VM SKU, and the number of nodes. KAITO reads that CR and orchestrates everything: node provisioning, driver installation, model download, inference engine startup, and service exposure. One YAML. One `kubectl apply`. Done.
- **vLLM by Default** — KAITO integrates with vLLM, a high-throughput LLM inference engine optimized for serving large models efficiently. vLLM supports continuous batching, PagedAttention for efficient GPU memory management, and OpenAI-compatible API endpoints out of the box.

**Key Phrase:** *Declare the model. KAITO delivers the infrastructure.*

---

### Slide 3: How KAITO Works — The Workspace CRD Deep Dive

**Concept:** The Workspace CRD is the single declarative interface between your intent and the GPU infrastructure.

**Key Points:**

- **The Anatomy of a Workspace CR:**

| Field | What It Controls | Example |
|---|---|---|
| `metadata.name` | StatefulSet and Service name | `workspace-phi-4-mini` |
| `metadata.annotations` | Runtime engine, resource bypass, LB exposure | `kaito.sh/runtime: "vLLM"` |
| `resource.instanceType` | GPU VM SKU (only with NAP enabled) | `Standard_NC24ads_A100_v4` |
| `resource.count` | Number of GPU nodes for distributed inference | `1` |
| `resource.labelSelector.matchLabels` | Target specific GPU node(s) | `apps: phi-4` |
| `inference.preset.name` | Pre-defined model from KAITO's model catalog | `phi-4-mini-instruct` |
| `inference.template` | Custom container spec for HuggingFace models | Full pod spec with probes |

- **Two Deployment Modes:**

| Mode | When to Use | `instanceType` | Node Provisioning |
|---|---|---|---|
| **NAP Enabled** (Karpenter) | Auto-provision GPU nodes on demand | Set it — KAITO provisions automatically | Automatic via Karpenter NodeClaims |
| **BYO Node** (NAP Disabled) | Pre-provisioned GPU node pool, full control | **Do NOT set it** — KAITO expects you to provide the node | Manual — you manage the node pool |

- **Key Gotcha — `instanceType` with NAP Disabled:** When `disableNodeAutoProvisioning=true` (BYO node mode), do **not** set `instanceType` in the workspace CR. KAITO expects you to provide the node yourself. If `instanceType` is set with NAP disabled, KAITO will reject the workspace with a "no ready nodes found" error. Comment it out or remove it entirely.

- **Preset vs. Custom Models:**
  - **Preset** — Community-maintained model definitions (Phi-4, DeepSeek, Llama, Mistral, etc.). One line: `inference.preset.name: phi-4-mini-instruct`. KAITO knows the image, the runtime, the probes.
  - **Custom** — Any HuggingFace model via `inference.template`. You define the container spec using KAITO's base image (`mcr.microsoft.com/aks/kaito/kaito-base:0.2.0`). Full control over probes, environment variables, and model parameters.

**Visual Idea:** A visual YAML breakdown — the Workspace CR displayed with color-coded sections: metadata (blue), resource (green), inference (orange). Arrows from each section point to the infrastructure component it controls: metadata → Service name, resource → GPU node, inference → vLLM container.

---

*This section sets the stage: you aren't showing a new Helm chart — you're showing a paradigm shift from "GPU infrastructure engineering" to "declare what you want and let KAITO build it."*

---
---

## Section 2: Infrastructure Setup — Building the GPU Foundation

> *"The hardest part of running AI on Kubernetes isn't the AI — it's the infrastructure. KAITO makes the infrastructure invisible."*

---

### Slide 4: Architecture Overview — What You're Building

**Hook:** A production-ready AKS cluster with GPU node pools, KAITO operator, and multi-model inference — in under 30 minutes of setup time.

**Key Points:**

- **The Target Architecture:**
  ```
  ┌────────────────────────────────────────────────────────┐
  │  AKS Cluster                                           │
  │                                                        │
  │  ┌──────────────────┐  ┌──────────────────────────────┐│
  │  │  System Node Pool │  │  GPU Node Pool (Spot)        ││
  │  │  Standard_D4s_v5  │  │  Standard_NC24ads_A100_v4   ││
  │  │  2 nodes           │  │  1-3 nodes (autoscale)      ││
  │  │                    │  │  NVIDIA A100 GPU (1 per node)││
  │  │  ┌──────────────┐ │  │                              ││
  │  │  │ KAITO        │ │  │  ┌────────────┐ ┌─────────┐ ││
  │  │  │ Operator     │ │  │  │ Phi-4 Mini │ │ SmolLM2 │ ││
  │  │  └──────────────┘ │  │  │ (vLLM)     │ │ (vLLM)  │ ││
  │  │  ┌──────────────┐ │  │  └────────────┘ └─────────┘ ││
  │  │  │ DaemonSets:  │ │  │  ┌─────────────────────────┐││
  │  │  │ nvidia-plugin│ │  │  │ DeepSeek R1 Llama 8B    │││
  │  │  │ NFD worker   │ │  │  │ (vLLM)                  │││
  │  │  │ GFD          │ │  │  └─────────────────────────┘││
  │  │  └──────────────┘ │  │                              ││
  │  └──────────────────┘  └──────────────────────────────┘│
  └────────────────────────────────────────────────────────┘
  ```

- **Key Design Decisions:**

| Decision | Choice | Why |
|---|---|---|
| **GPU SKU** | `Standard_NC24ads_A100_v4` | NVIDIA A100 — best price/performance for inference |
| **Node Priority** | Spot VMs | GPU VMs are expensive; Spot saves 60-90% |
| **Autoscaling** | Cluster Autoscaler (min 1, max 3) | Scale GPU nodes per model demand |
| **NAP** | Disabled (BYO node mode) | Full control over node pool configuration |
| **KAITO Install** | Helm (not managed add-on) | More configuration control, feature gates |
| **One GPU per Node** | Architecture constraint | `Standard_NC24ads_A100_v4` has 1 GPU — one model per node |

- **The Three Pillars of GPU Node Readiness:**

| Pillar | DaemonSet | What It Does | Why It Matters |
|---|---|---|---|
| **1. Device Plugin** | `nvidia-device-plugin` | Exposes `nvidia.com/gpu` as allocatable resource | Without it, Kubernetes can't schedule GPU workloads |
| **2. Node Feature Discovery** | NFD worker | Discovers PCI devices, adds `feature.node.kubernetes.io/pci-10de.present=true` label | GFD depends on this label to schedule |
| **3. GPU Feature Discovery** | GFD | Reads GPU info, adds `nvidia.com/*` labels (product, memory, etc.) | KAITO validates these labels before accepting workspace CRs |

- **The Dependency Chain:** `NFD → GFD → KAITO workspace validation`. If NFD doesn't run on the GPU node, GFD won't schedule. If GFD doesn't run, KAITO will reject the workspace with `missing required nvidia.com labels`.

**Visual Idea:** A layered dependency diagram showing the three DaemonSets stacking: NFD at the bottom (foundation), GFD in the middle (depends on NFD), KAITO workspace validation at the top (depends on GFD). Each layer shows what it produces (labels, resources) and what the next layer consumes.

**Speaker Notes:**
> This is the architecture slide that the audience should photograph. Walk through the design decisions table — stress the Spot VM choice: "A100 GPUs at $3.67/hour on-demand. On Spot? Under $1.50/hour. That's a 60% cost reduction for inference workloads that can tolerate preemption." The three-pillar dependency chain is the most common deployment blocker — if the audience remembers one thing from this slide, it should be: "NFD → GFD → KAITO. If any link breaks, the workspace CR fails."

---

### Slide 5: Cluster Provisioning — From Zero to GPU-Ready

**Hook:** A production-ready AKS cluster with identity, ACR, observability, Key Vault, and GPU nodes — automated end-to-end.

**Key Points:**

- **Step 1 — Variables and Resource Naming:**
  ```powershell
  $RAND = Get-Random
  $env:LOCATION = "swedencentral"
  $env:RG_NAME = "rg-aks-kaito-demo$RAND"
  $SHORT_SUFFIX = "$RAND".Substring(0, [Math]::Min(6, "$RAND".Length))

  $env:AKS_NAME = "aks-kaito-demo-$RAND"
  $env:USER_ASSIGNED_IDENTITY_NAME = "mi-kaito-demo$SHORT_SUFFIX"
  $env:ACR_NAME = "acrkaitodemo$SHORT_SUFFIX"  # Alphanumeric only, no hyphens
  ```

- **Step 2 — Preview Features and Provider Registration:**
  ```powershell
  az extension add --name aks-preview
  az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingFlowLogsPreview"
  az feature register --namespace "Microsoft.ContainerService" --name "AdvancedNetworkingL7PolicyPreview"
  az provider register --namespace Microsoft.ContainerService
  az provider register --namespace Microsoft.ContainerRegistry
  az provider register --namespace Microsoft.Insights
  # ... and other required providers
  ```

- **Step 3 — Resource Group, Identity, and ACR:**
  ```powershell
  az group create --name $env:RG_NAME --location $env:LOCATION

  # User-assigned managed identity
  az identity create --name $env:USER_ASSIGNED_IDENTITY_NAME `
      --resource-group $env:RG_NAME --location $env:LOCATION
  Start-Sleep -Seconds 30  # Wait for identity propagation

  # Azure Container Registry with system-assigned identity
  az acr create --resource-group $env:RG_NAME --name $env:ACR_NAME `
      --sku Standard --location $env:LOCATION
  az acr identity assign --identities "[system]" `
      --name $env:ACR_NAME --resource-group $env:RG_NAME
  ```

- **Step 4 — Observability Stack:**
  ```powershell
  # Log Analytics Workspace (with system-assigned identity)
  az monitor log-analytics workspace create --resource-group $env:RG_NAME `
      --workspace-name "mylogs$RAND" --identity-type SystemAssigned --location $env:LOCATION

  # Azure Monitor Workspace (Prometheus)
  az monitor account create --name "myprometheus$RAND" `
      --resource-group $env:RG_NAME --location $env:LOCATION

  # Application Insights (linked to Log Analytics)
  az monitor app-insights component create --app "myappinsights$RAND" `
      --location $env:LOCATION --resource-group $env:RG_NAME --workspace $LOG_WORKSPACE_ID
  ```

- **Step 5 — Key Vault with RBAC:**
  ```powershell
  az keyvault create --name "kv-$(Get-Random -Minimum 1000 -Maximum 9999)" `
      --resource-group $env:RG_NAME --location $env:LOCATION `
      --enable-rbac-authorization true --sku standard

  # Assign roles to managed identity and current user
  az role assignment create --role "Key Vault Secrets User" `
      --assignee $IDENTITY_PRINCIPAL_ID --scope $KV_ID
  az role assignment create --role "Key Vault Administrator" `
      --assignee $USER_OBJECT_ID --scope $KV_ID
  ```

- **Step 6 — Create the AKS Cluster:**
  ```powershell
  az aks create `
      --resource-group $env:RG_NAME `
      --name $env:AKS_NAME `
      --location $env:LOCATION `
      --kubernetes-version $K8S_VERSION `
      --attach-acr $env:ACR_NAME `
      --load-balancer-sku standard `
      --network-plugin azure `
      --network-plugin-mode overlay `
      --network-dataplane cilium `
      --network-policy cilium `
      --enable-managed-identity `
      --enable-workload-identity `
      --enable-oidc-issuer `
      --enable-addons monitoring `
      --ssh-access disabled
  ```

- **Step 7 — Node Pools and Key Vault Integration:**
  ```powershell
  # Add user node pool
  az aks nodepool add --resource-group $env:RG_NAME --cluster-name $env:AKS_NAME `
      --mode User --name userpool --node-count 2

  # Taint system node pool
  az aks nodepool update --resource-group $env:RG_NAME --cluster-name $env:AKS_NAME `
      --name systempool --node-taints CriticalAddonsOnly=true:NoSchedule

  # Enable Key Vault Secrets Provider addon
  az aks enable-addons --addons azure-keyvault-secrets-provider `
      --resource-group $env:RG_NAME --name $env:AKS_NAME
  ```

- **Step 8 — Add GPU Node Pool (Spot):**
  ```powershell
  az aks nodepool add --name nc24adsa100g `
      --resource-group $env:RG_NAME `
      --cluster-name $env:AKS_NAME `
      --node-vm-size Standard_NC24ads_A100_v4 `
      --tags EnableManagedGPUExperience=true `
      --node-count 1 `
      --priority Spot `
      --eviction-policy Delete `
      --enable-cluster-autoscaler `
      --ssh-access disabled `
      --min-count 1 `
      --max-count 3
  ```

- **Step 9 — Connect and Verify:**
  ```powershell
  az aks get-credentials --resource-group $env:RG_NAME --name $env:AKS_NAME --overwrite-existing
  kubectl get nodes  # Should see system, user, and GPU nodes
  ```

> **Note:** The full setup script with all resource naming, identity propagation waits, and RBAC assignments is available at [`setup.ps1`](headlamp/setup.ps1). You can run it end-to-end or step through each section.

- **The Infrastructure Stack You Get:**

| Resource | Purpose |
|---|---|
| Resource Group | Logical container for all resources |
| User-Assigned Managed Identity | Workload identity for AKS and Key Vault access |
| Azure Container Registry (Standard) | Container image storage with system-assigned identity |
| Log Analytics Workspace | Centralized logging with system-assigned identity |
| Azure Monitor Workspace | Prometheus metrics collection |
| Application Insights | Application performance monitoring |
| Key Vault (RBAC-enabled) | Secrets and certificate management |
| AKS Cluster | Kubernetes with CNI Overlay, Cilium, workload identity, OIDC |
| System Node Pool | Platform workloads with `CriticalAddonsOnly` taint |
| User Node Pool | Application workloads (2 nodes) |
| GPU Node Pool (Spot) | AI/LLM inference workloads (autoscale 1-3) |

- **Why Spot VMs?** — GPU VMs are the most expensive resources in Azure. A single `Standard_NC24ads_A100_v4` node costs ~$3.67/hour on-demand (~$2,680/month). On Spot, the same node is 60-90% cheaper. For inference workloads (stateless, restartable), Spot is the default choice. The tradeoff: Spot VMs can be evicted with 30 seconds notice. KAITO's StatefulSet will automatically reschedule the model on a new node.

- **The Spot Taint** — Spot nodes automatically receive the taint `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`. This prevents non-GPU workloads from landing on expensive GPU nodes — but it also blocks KAITO's own DaemonSets and model pods unless they have a matching toleration.

**Slogan:** *Three commands. Five minutes. GPU-ready.*

**Visual Idea:** A terminal recording showing the three-step setup — cluster creation, GPU node pool, credential setup — with timestamps showing the speed. A sidebar shows the estimated cost comparison: On-Demand vs. Spot pricing.

---

### Slide 6: Installing KAITO — Managed Add-On vs. Helm

**Hook:** Two paths to KAITO. The managed add-on for simplicity. Helm for control.

**Key Points:**

- **Option A — Managed Add-On:**
  - Installed with `--enable-ai-toolchain-operator` during cluster creation
  - Runs in `kube-system` namespace
  - Managed lifecycle — Azure handles upgrades
  - Limited configuration options
  - Best for: quick demos, proof of concept

- **Option B — Helm (Recommended for Production):**
  ```powershell
  helm repo add kaito https://kaito-project.github.io/kaito/charts/kaito
  helm repo update

  helm upgrade --install kaito-workspace kaito/workspace `
    --namespace kaito-workspace `
    --create-namespace `
    --set clusterName=$CLUSTER_NAME `
    --set defaultNodeImageFamily="ubuntu" `
    --set featureGates.gatewayAPIInferenceExtension=true `
    --set featureGates.disableNodeAutoProvisioning=true `
    --set gpu-feature-discovery.nfd.enabled=true `
    --set gpu-feature-discovery.gfd.enabled=true `
    --set nvidiaDevicePlugin.enabled=true
  ```

- **Key Helm Values Explained:**

| Value | What It Controls | Default |
|---|---|---|
| `defaultNodeImageFamily` | Node OS (`ubuntu` or `azurelinux`) | — |
| `disableNodeAutoProvisioning` | Prevents KAITO from creating Karpenter NodeClaims | `false` |
| `gpu-feature-discovery.nfd.enabled` | Deploys NFD worker DaemonSet | `true` |
| `gpu-feature-discovery.gfd.enabled` | Deploys GFD DaemonSet | `true` |
| `nvidiaDevicePlugin.enabled` | Deploys NVIDIA device plugin DaemonSet | `true` |
| `gatewayAPIInferenceExtension` | Enables Gateway API for inference routing | `false` |

- **Post-Install Verification:**
  ```powershell
  # Verify KAITO pods are running
  kubectl get pods -n kaito-workspace

  # Verify GPU capacity on node
  kubectl get nodes <gpu-node> -o yaml | Select-String "capacity" -Context 0,10
  # Should see: nvidia.com/gpu: "1"

  # Verify all three DaemonSets
  kubectl get daemonset -n kaito-workspace
  ```

**Visual Idea:** A decision tree — "Do you need full control over KAITO configuration?" → Yes → Helm. No → Managed Add-on. Below: a comparison table showing feature parity and differences.

---

### Slide 7: The Spot Taint Problem — And How to Solve It

**Hook:** The most common KAITO deployment failure. Three patches. One-time fix. Never worry about it again.

**Key Points:**

- **The Problem** — GPU Spot nodes have the taint `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`. This blocks *all* pods without a matching toleration — including the three DaemonSets KAITO needs to validate GPU nodes.

- **The Fix — Patch All Three DaemonSets:**
  ```powershell
  # 1. nvidia-device-plugin
  kubectl patch daemonset nvidia-device-plugin-daemonset -n kaito-workspace `
    --type='json' -p='[{
      "op": "add",
      "path": "/spec/template/spec/tolerations/-",
      "value": {
        "key": "kubernetes.azure.com/scalesetpriority",
        "operator": "Equal", "value": "spot", "effect": "NoSchedule"
      }
    }]'

  # 2. NFD Worker (Node Feature Discovery)
  kubectl patch daemonset kaito-workspace-node-feature-discovery-worker `
    -n kaito-workspace --type='json' -p='[{
      "op": "add",
      "path": "/spec/template/spec/tolerations/-",
      "value": {
        "key": "kubernetes.azure.com/scalesetpriority",
        "operator": "Equal", "value": "spot", "effect": "NoSchedule"
      }
    }]'

  # 3. GFD (GPU Feature Discovery)
  kubectl patch daemonset kaito-workspace-gpu-feature-discovery-gpu-feature-discovery `
    -n kaito-workspace --type='json' -p='[{
      "op": "add",
      "path": "/spec/template/spec/tolerations/-",
      "value": {
        "key": "kubernetes.azure.com/scalesetpriority",
        "operator": "Equal", "value": "spot", "effect": "NoSchedule"
      }
    }]'
  ```

- **One-Time Fix** — These patches only need to be done **once**. They automatically apply to any new GPU nodes that join the pool via the cluster autoscaler. New nodes scale up, DaemonSets schedule automatically, KAITO validates automatically.

- **Verify Everything Is Running:**
  ```powershell
  # All three DaemonSets should have pods on GPU nodes
  kubectl get pods -n kaito-workspace -o wide | Select-String "nvidia|nfd|gpu-feature"

  # GPU node should have nvidia.com labels
  kubectl get node <gpu-node> -o yaml | Select-String "nvidia.com"
  ```

**Slogan:** *Three patches. One time. Every GPU node — forever.*

**Visual Idea:** A "before/after" terminal screenshot. Before: three DaemonSet pods in `Pending` state, KAITO workspace CR rejected. After: three DaemonSet pods `Running` on GPU node, workspace CR accepted. The three patch commands highlighted in between.

**Speaker Notes:**
> This is the slide that saves the audience hours of debugging. Every KAITO deployment on Spot VMs hits this. Stress: "If you're using Spot GPU nodes — and you should be for cost reasons — you *will* need these three patches. Do them first. Do them once. Never think about them again." Walk through the dependency chain one more time: "NFD labels the node → GFD reads the labels → KAITO validates the labels. If any DaemonSet can't schedule due to the Spot taint, the whole chain breaks."

---

*This section gives the audience everything they need to build a GPU-ready AKS cluster with KAITO — from zero to operational in under 30 minutes.*

---
---

## Section 3: Deploying LLM Models — From YAML to Inference

> *"One YAML. One `kubectl apply`. One endpoint serving your model."*

---

### Slide 8: The Deployment Pattern — Consistent Across Every Model

**Hook:** Whether you're deploying Phi-4, DeepSeek, SmolLM2, or any HuggingFace model — the pattern is the same. Learn it once, deploy anything.

**Key Points:**

- **The Universal Deployment Pattern (BYO Node Mode):**
  ```
  Step 1: Label the GPU node     → kubectl label node <node> apps=<model-label>
  Step 2: Apply the workspace CR → kubectl apply -f <model>.yaml -n kaito-workspace
  Step 3: Patch Spot toleration   → kubectl patch statefulset <name> -n kaito-workspace ...
  Step 4: Verify                  → kubectl get pods -n kaito-workspace -w
  ```

- **What Happens Under the Hood:**
  1. You apply the Workspace CR → KAITO controller sees the new CR
  2. KAITO finds a GPU node matching `labelSelector.matchLabels`
  3. KAITO creates a StatefulSet with 1 replica
  4. The StatefulSet creates a Pod → Pod is `Pending` (Spot taint blocks it)
  5. You patch the StatefulSet with Spot toleration → Pod schedules
  6. vLLM downloads the model weights from HuggingFace (or MCR cache)
  7. vLLM loads the model into GPU memory
  8. Health/readiness probes pass → Pod becomes `Ready`
  9. Kubernetes Service exposes OpenAI-compatible API endpoints

- **Key Rules:**

| Rule | Why |
|---|---|
| Labels are **case-sensitive** | `apps: phi-4` ≠ `Apps: phi-4` |
| One GPU per node = one model per node | `Standard_NC24ads_A100_v4` has 1 A100 GPU |
| Don't set `instanceType` with NAP disabled | KAITO will reject with "no ready nodes found" |
| Always tolerate the Spot taint on model StatefulSets | Without it, the pod stays `Pending` forever |
| Delete Pending pods after labeling a new node | StatefulSet may not auto-reschedule |

- **Multi-Model Scaling** — Deploy a second model? The first GPU node is occupied. The cluster autoscaler provisions a new GPU node automatically. Label it, delete the Pending pod, and the model schedules on the new node. Your `--max-count` on the node pool determines how many models you can run concurrently.

**Visual Idea:** A flowchart showing the 4-step deployment pattern as a repeatable loop. On the right: a stack of model cards (Phi-4, DeepSeek, SmolLM2) all pointing to the same pattern. Below: a timeline showing how the cluster autoscaler scales GPU nodes as models are added.

---

### Slide 9: Deploying Phi-4 Mini — Preset Model Walkthrough

**Hook:** Your first model deployment. A Microsoft-built SLM running on your own infrastructure in under 10 minutes.

**Key Points:**

- **Why Phi-4 Mini?** — Microsoft's Phi-4-mini-instruct is a small language model (SLM) optimized for instruction-following tasks. It's fast, efficient, and runs comfortably on a single A100 GPU. Ideal for: coding assistance, document summarization, structured output generation, and edge inference.

- **The Workspace CR:**
  ```yaml
  apiVersion: kaito.sh/v1beta1
  kind: Workspace
  metadata:
    name: workspace-phi-4-mini
    annotations:
      kaito.sh/runtime: "vLLM"
  resource:
    #instanceType: Standard_NC24ads_A100_v4  # Commented out — BYO node mode
    count: 1
    labelSelector:
      matchLabels:
        apps: phi-4
  inference:
    preset:
      name: phi-4-mini-instruct
  ```

- **Deploy It:**
  ```powershell
  # Label the GPU node
  kubectl label node aks-nc24adsa100g-27564872-vmss000000 apps=phi-4

  # Apply the workspace CR
  kubectl apply -f kaito_phi_4_mini.yaml -n kaito-workspace

  # Wait for StatefulSet, then patch Spot toleration
  kubectl patch statefulset workspace-phi-4-mini -n kaito-workspace `
    --type='json' -p='[{
      "op": "add",
      "path": "/spec/template/spec/tolerations/-",
      "value": {
        "key": "kubernetes.azure.com/scalesetpriority",
        "operator": "Equal", "value": "spot", "effect": "NoSchedule"
      }
    }]'

  # Monitor until Ready
  kubectl get pods -n kaito-workspace -w | Select-String "workspace-phi"
  ```

- **Test the Model:**
  ```powershell
  # Port-forward the service
  kubectl port-forward svc/workspace-phi-4-mini -n kaito-workspace 8080:80

  # Chat with Phi-4
  curl -s -X POST http://localhost:8080/v1/chat/completions `
    -H "Content-Type: application/json" `
    -d '{
      "model": "phi-4-mini-instruct",
      "messages": [{"role": "user", "content": "What is Kubernetes?"}],
      "max_tokens": 50,
      "temperature": 0
    }' | jq
  ```

**Slogan:** *Label. Apply. Patch. Chat. Four steps to your own LLM endpoint.*

**Visual Idea:** A terminal recording showing the four-step deployment in real time — with the final `curl` response showing Phi-4's answer about Kubernetes. A "total time" counter in the corner showing ~8 minutes from start to first response.

---

### Slide 10: Deploying Custom Models — HuggingFace on KAITO

**Hook:** KAITO's preset catalog is powerful — but the real unlock is running *any* HuggingFace model on your GPU infrastructure.

**Key Points:**

- **When to Use Custom vs. Preset:**

| Scenario | Use |
|---|---|
| Model is in KAITO's catalog (Phi-4, DeepSeek, Llama, Mistral) | **Preset** — one line in the workspace CR |
| Model is on HuggingFace but not in KAITO's catalog | **Custom** — use `inference.template` with KAITO base image |
| Model is fine-tuned or private | **Custom** — point to your own image or HuggingFace repo |

- **Custom Model Workspace CR (SmolLM2-1.7B-Instruct):**
  ```yaml
  apiVersion: kaito.sh/v1beta1
  kind: Workspace
  metadata:
    name: workspace-custom-llm
  resource:
    #instanceType: "Standard_NC24ads_A100_v4"
    labelSelector:
      matchLabels:
        apps: custom-llm
  inference:
    template:
      spec:
        containers:
          - name: custom-llm-container
            image: mcr.microsoft.com/aks/kaito/kaito-base:0.2.0
            # ... probes, env vars, model config
  ```

- **The Key Difference** — With preset models, KAITO knows the image, runtime, and probes. With custom models, you provide the full container spec using KAITO's base image (`mcr.microsoft.com/aks/kaito/kaito-base:0.2.0`), which includes the HuggingFace runtime. The model ID for API calls is the HuggingFace model ID (e.g., `HuggingFaceTB/SmolLM2-1.7B-Instruct`).

- **Deploying the Custom Model:**
  ```powershell
  kubectl apply -f SmolLM2-1.7B-Instruct.yaml -n kaito-workspace

  # Patch Spot toleration
  kubectl patch statefulset workspace-custom-llm -n kaito-workspace `
    --type='json' -p='[{
      "op": "add",
      "path": "/spec/template/spec/tolerations/-",
      "value": {
        "key": "kubernetes.azure.com/scalesetpriority",
        "operator": "Equal", "value": "spot", "effect": "NoSchedule"
      }
    }]'
  ```

- **Multi-Model Scaling in Action** — If the first GPU node is occupied by Phi-4, deploying SmolLM2 triggers the cluster autoscaler to provision a second GPU node. Label the new node, delete the Pending pod, and the model schedules automatically.

**Slogan:** *If it's on HuggingFace, it runs on KAITO.*

---

### Slide 11: Deploying DeepSeek R1 — A Third Model at Scale

**Hook:** Three models, three GPU nodes, one cluster. This is multi-model inference at scale.

**Key Points:**

- **DeepSeek R1 Distill Llama 8B** — A distilled version of DeepSeek's R1 model based on the Llama 8B architecture. Optimized for reasoning tasks with chain-of-thought capabilities. KAITO preset: `deepseek-r1-distill-llama-8b`.

- **The Deployment:**
  ```powershell
  # Apply the workspace CR
  kubectl apply -f kaito_deepseek_r1_distill_llama_8b.yaml -n kaito-workspace

  # GPU nodes 1 and 2 are occupied → autoscaler provisions node 3
  kubectl get nodes -w  # Wait for new node

  # Label the new GPU node
  kubectl label node <new-gpu-node> apps=deepseek-r1-distill-llama-8b

  # Patch Spot toleration
  kubectl patch statefulset workspace-deepseek-r1-distill-llama-8b `
    -n kaito-workspace --type='json' -p='[{
      "op": "add",
      "path": "/spec/template/spec/tolerations/-",
      "value": {
        "key": "kubernetes.azure.com/scalesetpriority",
        "operator": "Equal", "value": "spot", "effect": "NoSchedule"
      }
    }]'

  # Delete the Pending pod so it reschedules on the new node
  kubectl delete pod workspace-deepseek-r1-distill-llama-8b-0 -n kaito-workspace
  ```

- **The Fleet View:**

| Model | Workspace Name | GPU Node | Preset/Custom | Use Case |
|---|---|---|---|---|
| Phi-4 Mini | `workspace-phi-4-mini` | GPU Node 1 | Preset | Coding, summarization |
| SmolLM2 1.7B | `workspace-custom-llm` | GPU Node 2 | Custom (HuggingFace) | Lightweight inference |
| DeepSeek R1 Llama 8B | `workspace-deepseek-r1-distill-llama-8b` | GPU Node 3 | Preset | Reasoning, chain-of-thought |

- **Cost Profile (Spot Pricing):**

| Nodes | On-Demand Cost | Spot Cost (est.) | Monthly Savings |
|---|---|---|---|
| 3x `Standard_NC24ads_A100_v4` | ~$8,040/month | ~$3,200/month | ~$4,840 |

**Slogan:** *Three models. Three nodes. One pattern. Sixty percent cost savings on Spot.*

**Visual Idea:** A "fleet dashboard" showing three model cards side by side — each with model name, GPU node, status (Running), and a sample prompt/response. Below: a cost comparison bar chart showing On-Demand vs. Spot pricing.

**Speaker Notes:**
> This is the "scale" moment. Walk through the progression: "We started with one model on one node. Then we added a custom HuggingFace model — the autoscaler added a second node. Now we're adding DeepSeek — a third node, a third model, same pattern every time." Stress the cost point: "On Spot, three A100 GPUs running three different LLMs costs about $3,200/month. On-demand, that's $8,000. Same models, same performance, 60% less."

---

*This section proved that model deployment on KAITO is a repeatable, consistent pattern — whether you're deploying a KAITO preset like Phi-4 or DeepSeek, or a custom HuggingFace model like SmolLM2. The cluster autoscaler handles GPU node provisioning, and Spot VMs deliver massive cost savings.*

---
---

## Section 3.5: Headlamp — A Visual Interface for KAITO

> *"Not everyone lives in the terminal. Headlamp gives you a dashboard for your AI workloads — deploy, monitor, and chat with your models without writing a single kubectl command."*

---

### Slide 11.5: What is Headlamp?

**Hook:** Headlamp is a Kubernetes dashboard built by Microsoft — and it's now part of the core Kubernetes project under SIG UI. With the KAITO plugin, it becomes the easiest way to deploy and manage AI models on your cluster.

**Key Points:**

- **Headlamp — The Kubernetes Dashboard That Doesn't Suck:**
  - Open-source project built by Microsoft
  - Recently accepted into the core Kubernetes project under Kubernetes SIG UI — this isn't a side project, it's the future of Kubernetes dashboards
  - Designed with extensibility in mind — you can customize and extend it with plugins
  - Supports connecting to multiple clusters at once
  - Provides real-time updates so you always see the current state of your resources
  - Modern, intuitive interface that works for both beginners and experienced Kubernetes users

- **Why Headlamp for KAITO?** — KAITO provides a dedicated Headlamp plugin that adds specialized features for managing KAITO workspaces. Instead of jumping between CLI and browser, you get a visual way to manage your GPU workloads, check inference status, and monitor model deployments — all from one dashboard.

- **Installing the KAITO Plugin:**
  1. Open Headlamp
  2. Go to the Plugin Catalog
  3. Search for **Headlamp KAITO**
  4. Install and reload
  5. Connect to your cluster

**Slogan:** *The dashboard your GPU workloads deserve.*

**Visual Idea:** A screenshot of Headlamp's main interface showing the KAITO plugin installed — with the KAITO button visible in the toolbar and a list of deployed workspaces in the main panel.

---

### Slide 11.6: Deploying Models via Headlamp — No YAML Required

**Hook:** Everything we did with `kubectl apply` and YAML files? Headlamp lets you do it with clicks.

**Key Points:**

- **Deploying a Model via the Dashboard:**
  1. Click the **KAITO** button on the toolbar — the Model Catalog opens
  2. The catalog presents a list of available preset workspaces — these are all the models you can deploy with KAITO
  3. Scroll through the list until you find the model you want, then click **Deploy**
  4. A panel opens with the YAML manifest of the workspace — you can deploy as-is or customize

- **Default vs. Customized Workspace:**

| Option | What It Does | Best For |
|---|---|---|
| **Default Workspace** | Preset configuration optimized for the most cost-effective VM size that meets the model's requirements | Most people — recommended starting point |
| **Customized Workspace** | Modify the YAML to use a different VM size, adjust parameters, or change resource settings | Users with specific requirements or quota constraints |

- **Monitoring Deployment Progress:**
  - After deploying, check the KAITO Workspace view to see progress
  - Make sure **Resource Ready**, **Inference Ready**, and **Workspace Ready** statuses are all set to ready
  - Deployment can take up to 15 minutes depending on model size and GPU node provisioning

**Slogan:** *Browse. Click. Deploy. Your model is serving in minutes.*

**Visual Idea:** A step-by-step screenshot flow — (1) KAITO button in toolbar → (2) Model Catalog with available models → (3) YAML editor panel → (4) Workspace status showing all three readiness indicators green.

---

### Slide 11.7: Testing Models via Headlamp Chat

**Hook:** Forget port-forwarding and curl commands. Headlamp has a built-in chat interface for testing your inference endpoints.

**Key Points:**

- **The Chat Interface:**
  - Click on the **Chat** menu in Headlamp when a workspace is ready
  - Select the workspace and model
  - Start testing — type prompts and get responses directly in the dashboard
  - You can also view workspace logs from the same interface — useful for debugging and troubleshooting issues

- **Tunable Prompt Parameters:**

| Parameter | What It Controls |
|---|---|
| **Temperature** | Randomness of the output — lower = more deterministic, higher = more creative |
| **Max Tokens** | Maximum length of the output |
| **Top P** | Diversity of the output (nucleus sampling) |
| **Top K** | Number of tokens to sample from |
| **Repetition Penalty** | Penalty for repeating tokens — higher = less repetition |

- **CLI vs. Headlamp — Two Paths, Same Result:**

| Approach | Best For |
|---|---|
| **CLI** (`curl` + port-forward) | Automation, CI/CD pipelines, scripting |
| **Headlamp Chat** | Interactive testing, demos, quick validation, troubleshooting |

**Slogan:** *Deploy with clicks. Test with chat. Debug with logs. All in one dashboard.*

**Visual Idea:** A screenshot of the Headlamp chat interface — a conversation with a KAITO model showing a prompt, response, and the settings panel open on the side with temperature/max tokens sliders.

**Speaker Notes:**
> This is the "wow" moment for people who aren't terminal-first. Walk through the flow: "Open Headlamp, click KAITO, browse the model catalog, click Deploy, wait for the readiness indicators to go green, then click Chat and start talking to your model. No YAML. No kubectl. No port-forwarding. Same model, same endpoint, same quality — just a different interface." Stress that both paths (CLI and Headlamp) are valid — CLI for automation, Headlamp for interactive work and demos.

---

*This section introduced Headlamp as the visual complement to KAITO's CLI-driven workflow — giving teams a dashboard-first experience for deploying, monitoring, and testing AI models on Kubernetes.*

---
---

## Section 4: Testing & Interacting with Models — The vLLM API

> *"Every KAITO model exposes the same OpenAI-compatible API. Learn it once, use it everywhere."*

---

### Slide 12: The vLLM API — OpenAI-Compatible Endpoints

**Hook:** KAITO runs models with vLLM, which exposes OpenAI-compatible API endpoints. Your existing OpenAI SDK code works out of the box — just change the base URL.

**Key Points:**

- **Available Endpoints:**

| Endpoint | Description | Best For |
|---|---|---|
| `/v1/models` | List available models | Discovery, health checks |
| `/v1/chat/completions` | Chat completions (messages format) | Conversational AI, chatbots |
| `/v1/completions` | Raw text completion | Code generation, text completion |
| `/v1/responses` | Simplified input/output format | Quick tests, simple queries |
| `/metrics` | Prometheus metrics | Monitoring, alerting |

- **Two Access Methods:**

| Method | How | Best For |
|---|---|---|
| **Nginx Jump Box** | Deploy `nginx` pod in-cluster, `kubectl exec` into it | Testing from within the cluster |
| **Port-Forward** | `kubectl port-forward svc/<workspace-name> -n kaito-workspace 8080:80` | Local development, quick tests |

- **Example — Chat Completions:**
  ```powershell
  # Port-forward first
  kubectl port-forward svc/workspace-phi-4-mini -n kaito-workspace 8080:80

  # Send a chat request
  curl -s -X POST http://localhost:8080/v1/chat/completions `
    -H "Content-Type: application/json" `
    -d '{
      "model": "phi-4-mini-instruct",
      "messages": [{"role": "user", "content": "Explain Kubernetes pods in 3 sentences."}],
      "max_tokens": 100,
      "temperature": 0
    }' | jq
  ```

- **PowerShell Gotcha** — When piping `curl.exe` output to `jq`, always use the `-s` flag (silent mode). Without it, the curl progress meter output corrupts the JSON and `jq` fails to parse it.

- **Custom Model API Calls** — For custom models (like SmolLM2), the model name in the API request is the HuggingFace model ID:
  ```powershell
  curl -s -X POST http://localhost:8080/v1/chat/completions `
    -H "Content-Type: application/json" `
    -d '{
      "model": "HuggingFaceTB/SmolLM2-1.7B-Instruct",
      "messages": [{"role": "user", "content": "What is Kubernetes?"}],
      "max_tokens": 50,
      "temperature": 0,
      "stream": false
    }' | jq
  ```

**Slogan:** *Same API as OpenAI. Your data never leaves your cluster.*

---

### Slide 13: Monitoring & Observability — GPU Metrics with Prometheus

**Hook:** Running an LLM without monitoring GPU utilization is like driving without a dashboard. vLLM gives you the dashboard for free.

**Key Points:**

- **Built-In Prometheus Metrics** — vLLM exposes detailed metrics at the `/metrics` endpoint: request throughput, latency percentiles, GPU memory utilization, batch sizes, cache hit rates, and token generation rates.

- **Scraping Metrics:**
  ```powershell
  # Direct scrape from in-cluster
  kubectl exec nginx -it -- curl http://workspace-phi-4-mini.kaito-workspace:80/metrics
  ```

- **ServiceMonitor for Managed Prometheus:**
  ```powershell
  # Label the inference service
  kubectl label svc workspace-phi-4-mini app=phi-4-mini -n kaito-workspace
  ```

  ```yaml
  # service_monitor.yaml
  apiVersion: azmonitoring.coreos.com/v1
  kind: ServiceMonitor
  metadata:
    name: prometheus-kaito-monitor
  spec:
    selector:
      matchLabels:
        app: phi-4-mini
    endpoints:
      - port: http
        interval: 30s
        path: /metrics
        scheme: http
  ```

  ```powershell
  kubectl apply -f service_monitor.yaml -n kube-system
  ```

- **Key Metrics to Watch:**

| Metric | What It Tells You | Action Threshold |
|---|---|---|
| GPU Memory Utilization | How much VRAM the model consumes | >90% → consider model quantization or larger GPU |
| Request Throughput | Requests per second | Scaling trigger for multi-replica serving |
| Latency (P95) | Response time at the 95th percentile | >2s → investigate batch size, model size |
| Cache Hit Rate | KV cache efficiency | Low hit rate → tune PagedAttention settings |

**Slogan:** *If you can't measure GPU utilization, you can't optimize GPU spend.*

**Visual Idea:** A Grafana dashboard mockup showing four panels: GPU Memory Utilization (gauge), Request Throughput (time series), Latency P95 (time series), and Active Models (table). All powered by the `/metrics` endpoint.

---

*This section showed that every KAITO model — preset or custom — exposes the same OpenAI-compatible API and Prometheus metrics. Testing, integration, and monitoring follow a single, consistent pattern.*

---
---

## Section 5: Lessons from Production — Gotchas, Patterns & Best Practices

> *"The difference between a demo and production is the lessons you've already learned the hard way."*

---

### Slide 14: The Top 8 Gotchas — Learned from Real Deployments

**Hook:** Every one of these cost us hours. Here's how to avoid them in minutes.

**Key Points:**

| # | Gotcha | What Happens | The Fix |
|---|---|---|---|
| 1 | **Spot taint not tolerated** | Model pods stay `Pending` forever | Patch StatefulSets AND DaemonSets with Spot toleration |
| 2 | **`instanceType` set with NAP disabled** | KAITO rejects workspace: "no ready nodes found" | Comment out `instanceType` in BYO node mode |
| 3 | **One GPU per node** | Second model can't schedule on occupied node | Let autoscaler provision new node, label it, delete Pending pod |
| 4 | **Node not labeled** | KAITO can't find a target node for the model | `kubectl label node <name> apps=<value>` — case-sensitive! |
| 5 | **DaemonSet tolerations missing** | NFD/GFD don't run on GPU node → KAITO rejects workspace | Patch all three DaemonSets once — applies to all future nodes |
| 6 | **Pending pod after new node scales up** | StatefulSet doesn't auto-reschedule | Delete the Pending pod — StatefulSet recreates it |
| 7 | **`curl` without `-s` flag** | Progress meter corrupts JSON, `jq` fails | Always use `curl -s` when piping to `jq` |
| 8 | **`/v1/responses` not documented** | Teams don't know about the simpler API format | Valid vLLM endpoint — use `input`/`max_output_tokens` instead of `messages` |

**Slogan:** *Eight gotchas. Eight fixes. Zero surprises in your next deployment.*

**Visual Idea:** A numbered "troubleshooting card" layout — each gotcha as a card with a red "symptom" section and a green "fix" section. Arranged in a 2x4 grid for easy scanning.

**Speaker Notes:**
> This is the slide the audience will screenshot and share with their team. Walk through the top 3 in detail (Spot taint, instanceType, one-GPU-per-node) — those are the ones that cause 80% of deployment failures. For the rest, point to the card and say: "It's all here. Save this slide." The emotional anchor: "Every one of these cost us hours of debugging. We're giving you the cheat sheet so you don't repeat our mistakes."

---

### Slide 15: Best Practices for Production KAITO Deployments

**Hook:** Demo-ready is not production-ready. Here's the gap — and how to close it.

**Key Points:**

- **Cost Optimization:**
  - Use Spot VMs for all inference workloads (60-90% savings)
  - Set `--max-count` on GPU node pools to prevent runaway autoscaling
  - Monitor GPU utilization — if consistently under 50%, consider smaller GPU SKUs or model quantization
  - Use the cluster autoscaler's `scale-down-delay-after-delete` to avoid premature GPU node termination

- **Reliability:**
  - Deploy models as StatefulSets (KAITO default) for stable network identities
  - Configure PodDisruptionBudgets for critical inference endpoints
  - Use node affinity + anti-affinity to spread models across availability zones
  - Set up liveness and readiness probes (KAITO presets include them; custom models need manual configuration)

- **Security:**
  - Keep inference services as ClusterIP (default) — don't expose via LoadBalancer unless absolutely necessary
  - If external access is required, use an ingress controller with TLS termination and authentication
  - Scan model container images for CVEs before deployment
  - Use RBAC to restrict who can create/modify Workspace CRs

- **Operational Excellence:**
  - Label GPU nodes consistently with a naming convention (e.g., `apps=<model-name>`)
  - Document the DaemonSet toleration patches in your runbook — new team members will hit this
  - Set up ServiceMonitors for all inference services → pipe metrics to Azure Managed Grafana
  - Keep a "model inventory" — which models run on which nodes, which workspace CRs are active

**Slogan:** *Production isn't a destination — it's a checklist.*

**Visual Idea:** A four-pillar framework (Cost, Reliability, Security, Operational Excellence) — each pillar with 3-4 checkboxes. A maturity indicator at the bottom: "Demo" → "Staging" → "Production-Ready."

---

### Slide 16: The Model Selection Decision Tree

**Hook:** Not every model needs an A100. Not every use case needs 70B parameters. Here's how to choose.

**Key Points:**

- **The Decision Tree:**
  ```
  What's the use case?
  │
  ├─ Quick responses, lightweight tasks → SmolLM2 1.7B (custom)
  │   GPU: Any NVIDIA GPU, fast inference, low cost
  │
  ├─ Coding assistance, summarization, structured output → Phi-4 Mini (preset)
  │   GPU: A100 or equivalent, excellent quality-to-cost ratio
  │
  ├─ Reasoning, chain-of-thought, complex analysis → DeepSeek R1 (preset)
  │   GPU: A100, strong reasoning capabilities
  │
  ├─ Enterprise chat, general-purpose → Llama 3 / Mistral (preset)
  │   GPU: A100 or multi-GPU for larger variants
  │
  └─ Domain-specific / fine-tuned → Custom HuggingFace model (template)
      GPU: Depends on model size and quantization
  ```

- **GPU SKU Selection:**

| Model Size | Recommended GPU | Azure SKU | Cost (Spot, est.) |
|---|---|---|---|
| < 3B parameters | T4, A10 | `Standard_NC6s_v3` | ~$0.40/hr |
| 3B - 8B parameters | A100 (40GB) | `Standard_NC24ads_A100_v4` | ~$1.50/hr |
| 8B - 70B parameters | A100 (80GB) or multi-GPU | `Standard_ND96asr_v4` | ~$6.00/hr |
| > 70B parameters | Multi-node distributed | Multiple `Standard_ND96asr_v4` | ~$12.00+/hr |

**Slogan:** *Right model. Right GPU. Right cost. Every time.*

---

*This section distilled real-world deployment experience into actionable gotchas, best practices, and decision frameworks — the knowledge that separates a demo from a production deployment.*

---
---

## Section 6: Real-World Scenarios — KAITO in Action

> *"Theory is convincing. But running three models on Spot GPUs at 60% cost savings — that's proof."*

---

### Slide 17: Scenario 1 — Internal Copilot on Your Own Infrastructure

**Hook:** Your legal team wants an AI assistant for contract review — but data cannot leave your network. KAITO solves this.

**Key Points:**

- **The Requirement:**
  - AI-powered document analysis for legal contracts
  - Data sovereignty: no data leaves the corporate network
  - Cost-effective: not $30/user/month for external API access
  - Scalable: start with legal, expand to HR, engineering

- **The KAITO Solution:**
  ```
  1. Deploy AKS cluster with GPU node pool (private API server)
  2. Install KAITO via Helm
  3. Deploy Phi-4 Mini for summarization + structured extraction
  4. Expose via ClusterIP → ingress with AAD authentication
  5. Legal team accesses via internal URL — data never leaves Azure VNet
  ```

- **The ROI:**
  - External API (GPT-4o via OpenAI): ~$30/user/month × 50 users = **$1,500/month**
  - KAITO on Spot A100: ~**$1,100/month** (1 GPU node, unlimited users)
  - Break-even at ~37 users. Beyond that, KAITO is pure savings.
  - Plus: **zero data exfiltration risk**, full audit trail, model version control

**Slogan:** *Your model. Your network. Your data. Your savings.*

---

### Slide 18: Scenario 2 — Multi-Model Inference Platform

**Hook:** Different teams need different models. KAITO runs them all on one cluster.

**Key Points:**

- **The Multi-Model Architecture:**

| Team | Model | Use Case | Workspace |
|---|---|---|---|
| Engineering | Phi-4 Mini | Code review, documentation | `workspace-phi-4-mini` |
| Data Science | DeepSeek R1 | Reasoning, analysis | `workspace-deepseek-r1-distill-llama-8b` |
| Product | SmolLM2 | Quick Q&A, lightweight tasks | `workspace-custom-llm` |
| Research | Custom fine-tuned model | Domain-specific inference | `workspace-research-llm` |

- **The Operational Model:**
  - Shared GPU node pool with autoscaler (min 1, max 5)
  - Each team gets a dedicated Workspace CR and service endpoint
  - Namespace isolation for RBAC — teams can only manage their own models
  - Shared Prometheus monitoring — centralized GPU utilization dashboard
  - Platform team manages infrastructure; product teams manage models

- **Cost at Scale:**
  - 4 models on 4 Spot A100 nodes: ~$4,300/month
  - Equivalent external API usage: ~$6,000-10,000/month
  - Savings increase with usage — KAITO cost is fixed per GPU, not per token

**Slogan:** *One cluster. Four teams. Four models. One bill.*

---

### Slide 19: Scenario 3 — From Prototype to Production in One Day

**Hook:** Your ML team fine-tuned a model on HuggingFace. They need a production inference endpoint by tomorrow. KAITO: done by lunch.

**Key Points:**

- **The Workflow:**
  ```
  Morning:
    1. ML team pushes fine-tuned model to HuggingFace Hub (private repo)
    2. Platform engineer creates custom Workspace CR:
       - Points to HuggingFace model ID
       - Uses KAITO base image
       - Configures health probes and resource limits
    3. kubectl apply -f custom-model.yaml -n kaito-workspace
    4. Wait for model to download and load (~15-30 minutes for 8B model)
    5. Port-forward → test → verify quality

  Afternoon:
    6. Configure ingress with TLS + authentication
    7. Set up ServiceMonitor → Grafana dashboard
    8. Hand off endpoint URL to the application team
    9. Application team integrates via standard OpenAI SDK
       (just change base_url to the internal endpoint)
  ```

- **The Key Insight** — The application team's code doesn't change. They're already using the OpenAI SDK. Switching from `api.openai.com` to `kaito-inference.internal.company.com` is a one-line configuration change. Same SDK. Same API format. Different backend.

**Slogan:** *Fine-tuned at midnight. Serving at noon. Zero code changes for the application team.*

---

*This section grounded KAITO in real business scenarios: data sovereignty for regulated industries, multi-team model serving on shared infrastructure, and rapid prototype-to-production workflows — all powered by the same Workspace CRD pattern.*

---
---

## Section 7: Resource Hub — Reference & Useful Links

> *"Everything you need to get started — in one place."*

---

### Slide 20: Getting Started — Your First Fifteen Minutes

**Hook:** You've seen the architecture, the patterns, and the scenarios. Here's how to have your first LLM running in fifteen minutes.

**Key Points:**

- **Step 1: Create AKS Cluster with GPU Node Pool (5 min)**
  ```powershell
  az group create --name rg-aks-kaito --location swedencentral
  az aks create -g rg-aks-kaito -n kaito-cluster --enable-oidc-issuer
  az aks nodepool add --name gpupool -g rg-aks-kaito --cluster-name kaito-cluster `
      --node-vm-size Standard_NC24ads_A100_v4 --priority Spot --node-count 1 `
      --enable-cluster-autoscaler --min-count 1 --max-count 3 `
      --tags EnableManagedGPUExperience=true
  az aks get-credentials -g rg-aks-kaito -n kaito-cluster
  ```

- **Step 2: Install KAITO via Helm (2 min)**
  ```powershell
  helm repo add kaito https://kaito-project.github.io/kaito/charts/kaito && helm repo update
  helm upgrade --install kaito-workspace kaito/workspace -n kaito-workspace --create-namespace `
      --set featureGates.disableNodeAutoProvisioning=true `
      --set clusterName=kaito-cluster
  ```

- **Step 3: Patch DaemonSets for Spot Toleration (1 min)**
  ```powershell
  # Run the three kubectl patch commands from Slide 7
  ```

- **Step 4: Deploy Your First Model (3 min)**
  ```powershell
  kubectl label node <gpu-node> apps=phi-4
  kubectl apply -f kaito_phi_4_mini.yaml -n kaito-workspace
  # Patch StatefulSet toleration, wait for Ready
  ```

- **Step 5: Chat with Your Model (1 min)**
  ```powershell
  kubectl port-forward svc/workspace-phi-4-mini -n kaito-workspace 8080:80
  curl -s -X POST http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" `
      -d '{"model":"phi-4-mini-instruct","messages":[{"role":"user","content":"Hello!"}],"max_tokens":50}' | jq
  ```

**Slogan:** *Fifteen minutes to your own LLM. On your own infrastructure. Under your control.*

---

### Slide 21: Reference Links & Resources

**Key Resources:**

| Resource | Link | Description |
|---|---|---|
| **KAITO GitHub** | [github.com/kaito-project/kaito](https://github.com/kaito-project/kaito) | Source code, issues, and releases |
| **KAITO Helm Charts** | [kaito-project.github.io/kaito/charts/kaito](https://kaito-project.github.io/kaito/charts/kaito) | Helm chart repository |
| **KAITO Model Catalog** | [github.com/kaito-project/kaito/tree/main/presets](https://github.com/kaito-project/kaito/tree/main/presets) | Supported preset models |
| **AKS + KAITO Docs** | [learn.microsoft.com/azure/aks/ai-toolchain-operator](https://learn.microsoft.com/en-us/azure/aks/ai-toolchain-operator) | Official AKS documentation for KAITO |
| **vLLM Documentation** | [docs.vllm.ai](https://docs.vllm.ai) | vLLM inference engine docs |
| **CNCF Sandbox** | [cncf.io/projects/kaito](https://www.cncf.io/projects/kaito/) | KAITO's CNCF Sandbox page |
| **Azure GPU VM Pricing** | [azure.microsoft.com/pricing/details/virtual-machines](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/) | GPU VM SKU pricing and availability |
| **HuggingFace Model Hub** | [huggingface.co/models](https://huggingface.co/models) | Browse models for custom deployments |
| **Phi-4 Mini** | [huggingface.co/microsoft/phi-4-mini-instruct](https://huggingface.co/microsoft/phi-4-mini-instruct) | Microsoft's small language model |
| **DeepSeek R1** | [huggingface.co/deepseek-ai](https://huggingface.co/deepseek-ai) | DeepSeek reasoning models |
| **Prometheus Monitoring** | [prometheus.io](https://prometheus.io) | Metrics collection for vLLM endpoints |
| **AKS Extension for VS Code** | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-aks-tools) | AKS management and MCP setup |
| **Headlamp** | [headlamp.dev](https://headlamp.dev/) | Kubernetes dashboard — downloads and documentation |
| **Headlamp GitHub** | [github.com/headlamp-k8s/headlamp](https://github.com/headlamp-k8s/headlamp) | Source code and contributions |
| **Headlamp Plugin Dev Guide** | [headlamp.dev/docs/latest/development/plugins](https://headlamp.dev/docs/latest/development/plugins/) | Creating custom Headlamp extensions |

**Community & Support:**
- KAITO GitHub Issues — for feature requests and bug reports
- CNCF Slack `#kaito` channel — community discussion
- Azure Kubernetes Service documentation — official docs
- Azure Support — for production AKS + GPU issues

---

### Slide 22: Closing — AI Infrastructure Shouldn't Be the Bottleneck

**Hook:** Your ML team's velocity shouldn't be gated by GPU infrastructure complexity. KAITO removes the gate.

**Key Points:**

- **What You Saw Today:**
  1. **The Problem** — Running LLMs on Kubernetes requires deep GPU infrastructure expertise that most platform teams don't have. The complexity tax is real: drivers, plugins, discovery, taints, tolerations, inference engines.
  2. **The Solution** — KAITO abstracts the entire GPU stack behind a single Kubernetes CRD. One YAML. One `kubectl apply`. One OpenAI-compatible endpoint.
  3. **The Infrastructure** — A production-ready stack with ACR, observability (Log Analytics, Prometheus, App Insights), Key Vault with RBAC, workload identity, and Cilium networking — automated end-to-end via `setup.ps1`.
  4. **The Pattern** — Label, Apply, Patch, Chat. The same four-step pattern works for every model — preset or custom, 1.7B parameters or 70B.
  5. **The Dashboard** — Headlamp with the KAITO plugin gives you a visual interface to browse the model catalog, deploy workspaces, monitor readiness, and chat with your models — no terminal required.
  6. **The Economics** — Spot VMs deliver 60-90% cost savings on GPU infrastructure. One KAITO cluster serving four models costs less than external API access for 50 users.
  7. **The Ecosystem** — CNCF Sandbox project. vLLM for inference. Prometheus for monitoring. HuggingFace for models. Headlamp for dashboards. OpenAI-compatible API for integration. No lock-in at any layer.

- **The Call to Action:**
  - **This week:** Deploy your first KAITO model on a test cluster. Follow the 15-minute quickstart.
  - **This month:** Deploy a second model (custom HuggingFace). Set up monitoring with ServiceMonitor + Grafana.
  - **This quarter:** Build a multi-model inference platform. Move one team from external API to self-hosted inference. Measure cost savings.
  - **This year:** Run your organization's inference platform on KAITO. Every team, every model, one cluster, one operational pattern.

**Closing Line:** *Leading organizations aren't just running Kubernetes — they're running intelligence on Kubernetes. KAITO is how you get there. The infrastructure is ready. The models are waiting. Start today.*

**Visual Idea:** The opening quote returns on screen, now with the full architecture diagram behind it — AKS cluster, GPU node pool, KAITO operator, three models running, Prometheus metrics flowing. A single call-to-action: "Start today. Fifteen minutes."

**Speaker Notes:**
> Slow down for the closing. Revisit the opening quote — it should now carry more weight after 22 slides of substance. The call-to-action is deliberately time-boxed: "this week, this month, this quarter, this year." Give the audience a roadmap, not just inspiration. End by saying: "The complexity tax on GPU infrastructure has been the bottleneck holding back enterprise AI adoption on Kubernetes. KAITO eliminates that tax. The only question is: which model will you deploy first?" Pause. Thank the audience. Open for Q&A.
