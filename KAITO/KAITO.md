# Running AI & LLM Models on AKS with KAITO

**KAITO** — Kubernetes AI Toolchain Operator

---

## Why KAITO?

- Provisions GPU node pools
- Installs required NVIDIA GPU drivers
- Installs the device plugin for GPU
- Runs the model on GPU VMs using vLLM
- Exposes an endpoint for inference through a Kubernetes service
- Scales to meet customer demand
- Monitors GPU usage
- Supports RAG engine implementation

---

## Background

KAITO is a CNCF Sandbox project that simplifies and optimizes inference and tuning workloads on Kubernetes. By default, it integrates with **vLLM**, a high-throughput LLM inference engine optimized for serving large models efficiently.

KAITO can also run RAG workloads using the RAG engine, which is based on the Haystack framework.

---

## How KAITO Works — The Workspace CRD

To deploy an LLM model we use the **KAITO CRD** — specifically a `Workspace` resource from `kaito.sh/v1beta1`.

In the workspace CR we:

- **Give it a name** — this becomes the StatefulSet and Service name (e.g. `workspace-phi-4-mini`)
- **Specify annotations** — e.g. run the LLM model as vLLM or transformers, bypass resource checks, enable load balancer (creates a public IP so you can chat with the model directly)
- **Define the resource section** — describes the `instanceType` (the GPU VM SKU we want to use). Most of the time this matches what we've already created in the node pool and KAITO will pick and use the existing node. If the node doesn't exist and NAP (Karpenter) is enabled, it will create one automatically using Karpenter behind the scenes
- **Specify the number of GPU nodes** — we can run LLMs across multiple nodes and distribute the calculations
- **Set `matchLabels`** — these help pick which specific VM/node to run the LLM on
- **Define the inference section** — we specify a `preset` name, which is a preset model predefined by the KAITO community

> **Key Gotcha — `instanceType` with NAP disabled:** When `disableNodeAutoProvisioning=true` (BYO node mode), do **not** set `instanceType` in the workspace CR. KAITO expects you to provide the node yourself. If `instanceType` is set with NAP disabled, KAITO will reject the workspace with a "no ready nodes found" error. Comment it out or remove it entirely.

---

## Demo

Deploy LLM models into an AKS cluster using KAITO, then chat with them.

### Prerequisites

- AKS cluster
- Node pool with NVIDIA GPU (SKU: `Standard_NC24ads_A100_v4` — runs NVIDIA A100 GPU)
- LLM model supported by KAITO

### Infrastructure Setup Notes

- **Spot VMs** — GPU VMs are expensive, so Spot is used for cost savings
- **KAITO installed** via `--enable-ai-toolchain-operator` or Helm
- **NAP (Karpenter) disabled** — node pool and VMs are pre-provisioned for full control
- **One GPU per node** — each `Standard_NC24ads_A100_v4` node has **1 GPU**, meaning one model per node. If you deploy multiple models, the cluster autoscaler will scale up additional GPU nodes automatically

---

## KAITO Deployment

- KAITO can be deployed in two ways on AKS
- **AKS add-on**: This is the easiest way to deploy KAITO on AKS however you will be limited in terms of getting the latest features and updates as soon as they are available upstream.
- **Open source**: This requires more steps to deploy but you will have access to the latest features and updates as soon as they are available. To deploy open-source KAITO on AKS, you can deploy with **Terraform** or deploy with **Helm** and Azure CLI.

---

## CLI Commands

### Set Variables

```powershell
$RG = "rg-aks-kaito-demo"
$LOCATION = "swedencentral"
$CLUSTER_NAME = "kaito-aks-cluster"
```

### Create Resource Group and AKS Cluster

**Option 1 — With KAITO managed add-on:**

```powershell
az group create --name $RG --location $LOCATION

az aks create -g $RG -n $CLUSTER_NAME `
    --enable-oidc-issuer `
    --enable-ai-toolchain-operator
```

> This installs KAITO as a managed AKS add-on in the `kube-system` namespace.

**Option 2 — Without add-on (install KAITO via Helm later):**

```powershell
az group create --name $RG --location $LOCATION

az aks create -g $RG -n $CLUSTER_NAME --enable-oidc-issuer
```

### Add GPU Node Pool (Spot)

> **Note:** The tag `EnableManagedGPUExperience=true` enables the managed GPU node pool experience.

```powershell
az aks nodepool add --name nc24adsa100g `
    --resource-group $RG `
    --cluster-name $CLUSTER_NAME `
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

### Connect to the Cluster

```powershell
az aks get-credentials -g $RG -n $CLUSTER_NAME --overwrite-existing
```

---

## Install KAITO via Helm

If you did **not** use `--enable-ai-toolchain-operator`, install KAITO using Helm:

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

> **Notes:**
>
> - `defaultNodeImageFamily` can be either `ubuntu` or `azurelinux`
> - `gpu-feature-discovery.nfd.enabled`, `gpu-feature-discovery.gfd.enabled`, and `nvidiaDevicePlugin.enabled` are `true` by default in the chart
> - `disableNodeAutoProvisioning=true` prevents KAITO from creating NodeClaims (Karpenter) — required when using BYO node pools

---

## Verify the Setup

### Verify Nodes

```powershell
kubectl get nodes
```

Expected output:

```text
NAME                                  STATUS   ROLES    AGE     VERSION
aks-nc24adsa100-86536742-vmss000000   Ready    <none>   4m3s    v1.33.7
aks-nodepool1-36997821-vmss000000     Ready    <none>   9m44s   v1.33.7
aks-nodepool1-36997821-vmss000001     Ready    <none>   10m     v1.33.7
```

### Verify GPU Capacity

```powershell
kubectl get nodes aks-nc24adsa100g-27564872-vmss000000 -o yaml | Select-String "capacity" -Context 0,10
```

> Should see `nvidia.com/gpu: "1"` under `capacity`.

### Verify KAITO Pods

**If installed via Helm:**

```powershell
kubectl get pods -n kaito-workspace
```

**If installed via `--enable-ai-toolchain-operator`:**

```powershell
kubectl get pods -n kube-system | Select-String "kaito"
```

### Check Spot Taint on GPU Node

```powershell
kubectl get node aks-nc24adsa100g-27564872-vmss000000 -o yaml | Select-String "taint" -Context 0,10
```

### Check DaemonSets

```powershell
kubectl get daemonset -n kaito-workspace
```

---

## Spot Taint and DaemonSet Tolerations

The GPU nodes run as **Spot instances** and have a taint:

```text
kubernetes.azure.com/scalesetpriority=spot:NoSchedule
```

This means no Pod can schedule on those nodes unless it has a matching toleration. This prevents non-GPU workloads from landing on expensive GPU nodes.

> **Don't forget to tolerate the taints for the Spot instances!** This applies to the daemonsets, the model StatefulSets, and any other pod that needs to run on GPU nodes.

Three daemonsets need the Spot toleration to run on the GPU node. Without all three, KAITO cannot validate the workspace CR:

1. **nvidia-device-plugin** — exposes `nvidia.com/gpu` as an allocatable resource
2. **NFD worker** (Node Feature Discovery) — discovers PCI devices and adds `feature.node.kubernetes.io/pci-10de.present=true` label
3. **GFD** (GPU Feature Discovery) — reads GPU info and adds `nvidia.com/*` labels (e.g. `nvidia.com/gpu.product`, `nvidia.com/gpu.memory`). Requires the NFD label to schedule.

> **Important:** The dependency chain is: **NFD** → **GFD** → **KAITO workspace validation**. If NFD doesn't run on the GPU node, GFD won't schedule. If GFD doesn't run, KAITO will reject the workspace with `missing required nvidia.com labels`.

### Patch DaemonSets for Spot Toleration

> **Note:** These patches only need to be done **once**. They automatically apply to any new GPU nodes that join the pool via the cluster autoscaler.

**1. nvidia-device-plugin**

```powershell
kubectl patch daemonset nvidia-device-plugin-daemonset -n kaito-workspace --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "kubernetes.azure.com/scalesetpriority",
      "operator": "Equal",
      "value": "spot",
      "effect": "NoSchedule"
    }
  }
]'
```

**2. NFD Worker (Node Feature Discovery)**

```powershell
kubectl patch daemonset kaito-workspace-node-feature-discovery-worker -n kaito-workspace --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "kubernetes.azure.com/scalesetpriority",
      "operator": "Equal",
      "value": "spot",
      "effect": "NoSchedule"
    }
  }
]'
```

**3. GFD (GPU Feature Discovery)**

```powershell
kubectl patch daemonset kaito-workspace-gpu-feature-discovery-gpu-feature-discovery -n kaito-workspace --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "kubernetes.azure.com/scalesetpriority",
      "operator": "Equal",
      "value": "spot",
      "effect": "NoSchedule"
    }
  }
]'
```

### Verify All Pods Running on GPU Node

```powershell
kubectl get pods -n kaito-workspace -o wide | Select-String "nvidia|nfd|gpu-feature"
```

All three daemonsets should show a pod running on the GPU node (`aks-nc24adsa100g-*`).

### Verify nvidia.com Labels on GPU Node

```powershell
kubectl get node aks-nc24adsa100g-27564872-vmss000000 -o yaml | Select-String "nvidia.com"
```

Should see labels like `nvidia.com/gpu.product`, `nvidia.com/gpu.memory`, etc. in addition to the resource `nvidia.com/gpu: "1"`.

---

## Deploy LLM Model Using KAITO (Phi-4-mini-instruct)

The standard deployment pattern for any model on KAITO with BYO node mode:

1. **Label the GPU node** with the `matchLabels` value from the workspace CR
2. **Apply the workspace CR** — KAITO creates a StatefulSet
3. **Patch the StatefulSet** with the Spot toleration so the Pod can schedule
4. **If Pending** — check if the GPU is already occupied; if so, wait for the autoscaler to provision a new node, label it, and delete the pending pod

Key things to know:

- NAP (Node Auto-Provisioning / Karpenter) is **disabled** — we use BYO (Bring Your Own) node mode with a pre-provisioned GPU node pool
- The workspace CR must **not** have `instanceType` set when NAP is disabled — KAITO expects you to provide the node yourself
- The workspace spec has `labelSelector.matchLabels.apps: phi-4` so KAITO targets the specific GPU node with that label
- Labels are **case-sensitive** — `apps: phi-4` and `Apps: phi-4` are different labels
- KAITO creates a StatefulSet which deploys a Pod onto the matched GPU node, but the Pod will be blocked by the Spot taint unless a toleration is added

### Label the GPU Node

```powershell
kubectl label node aks-nc24adsa100g-27564872-vmss000000 apps=phi-4
```

### Apply the Workspace CR

```powershell
kubectl apply -f kaito_phi_4_mini.yaml -n kaito-workspace
```

### Monitor the Deployment

```powershell
kubectl get workspace -n kaito-workspace
kubectl get pods -n kaito-workspace
```

### Add Spot Toleration to the Model StatefulSet

Once the StatefulSet is created, the model Pod will be Pending due to the Spot taint. Patch it:

```powershell
kubectl get statefulset -n kaito-workspace

kubectl patch statefulset workspace-phi-4-mini -n kaito-workspace --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "kubernetes.azure.com/scalesetpriority",
      "operator": "Equal",
      "value": "spot",
      "effect": "NoSchedule"
    }
  }
]'
```

---

## Testing the Model (Phi-4)

The workspace service is **ClusterIP** — it's only reachable from inside the cluster. You have two options to test.

### vLLM Endpoints

KAITO runs models using vLLM, which exposes several OpenAI-compatible API endpoints:

| Endpoint | Description |
|---|---|
| `/v1/models` | List available models |
| `/v1/chat/completions` | Chat completions (messages format) |
| `/v1/completions` | Raw text completion |
| `/v1/responses` | Input/output format (simpler than chat) |

> **Tip (PowerShell):** When piping `curl.exe` output to `jq`, always use the `-s` flag (silent mode). Without it, the curl progress meter output corrupts the JSON and `jq` fails to parse it.

### Option A — Nginx Jump Box (In-Cluster)

Deploy an nginx pod as a jump box inside the cluster:

```powershell
# Watch for the model pod to become Ready
kubectl get pods -n kaito-workspace -w | Select-String "workspace-phi"

# Deploy nginx jump box
kubectl run nginx --image=nginx
kubectl exec nginx -it -- apt-get update
kubectl exec nginx -it -- apt-get install jq -y

# Verify the service endpoint
kubectl get svc -n kaito-workspace
```

**List available models:**

```powershell
kubectl exec nginx -it -- curl -s http://workspace-phi-4-mini.kaito-workspace/v1/models | jq
```

**Chat completions (messages format):**

```powershell
kubectl exec nginx -it -- curl -X POST http://workspace-phi-4-mini.kaito-workspace/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "phi-4-mini-instruct",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0
  }' | jq
```

**Responses endpoint (input/output format):**

```powershell
kubectl exec nginx -it -- curl -X POST "http://workspace-phi-4-mini.kaito-workspace/v1/responses" -H "Content-Type: application/json" -d '{
    "model": "phi-4-mini-instruct",
    "input": "What is Kubernetes?",
    "max_output_tokens": 200
  }' | jq
```

### Option B — Port-Forward (Local)

```powershell
kubectl port-forward svc/workspace-phi-4-mini -n kaito-workspace 8080:80
```

Then in another terminal:

**List available models:**

```powershell
curl -s http://localhost:8080/v1/models | jq
```

**Chat completions:**

```powershell
curl -s -X POST http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "phi-4-mini-instruct",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0
  }' | jq
```

**Responses endpoint:**

```powershell
curl -s -X POST http://localhost:8080/v1/responses -H "Content-Type: application/json" -d '{
    "model": "phi-4-mini-instruct",
    "input": "What is Kubernetes?",
    "max_output_tokens": 200
  }' | jq
```

---

## Deploying Custom Preset Models (SmolLM2-1.7B-Instruct)

This follows the same deployment pattern. The key difference is that this is a custom preset — the model name in the workspace CR is whatever you set, and the model name for API calls is the HuggingFace model ID.

### Apply the Workspace CR

```powershell
kubectl apply -f SmolLM2-1.7B-Instruct.yaml -n kaito-workspace
```

### Add Spot Toleration to the Model StatefulSet

Once the StatefulSet is created, the model Pod will be Pending due to the Spot taint. Patch it:

```powershell
kubectl get statefulset -n kaito-workspace

kubectl patch statefulset workspace-custom-llm -n kaito-workspace --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "kubernetes.azure.com/scalesetpriority",
      "operator": "Equal",
      "value": "spot",
      "effect": "NoSchedule"
    }
  }
]'
```

### Insufficient GPU — Scaling Up a Second GPU Node

If the pod remains `Pending` after the toleration patch, check the events:

```powershell
kubectl describe pod workspace-custom-llm-0 -n kaito-workspace | Select-String "Events" -Context 0,15
```

You may see:

```text
Warning  FailedScheduling  default-scheduler  0/4 nodes are available: 1 Insufficient nvidia.com/gpu,
3 node(s) didn't match Pod's node affinity/selector.
Normal   TriggeredScaleUp  cluster-autoscaler  pod triggered scale-up: [{aks-nc24adsa100g-27564872-vmss 1->2 (max: 3)}]
```

This means the existing GPU node is already fully occupied by another model (e.g. `workspace-phi-4-mini`). Each GPU node has only **1 GPU** — one model per node. The cluster autoscaler will provision a second GPU node automatically.

**Wait for the new node**, then label it:

```powershell
# Watch for the new node to become Ready
kubectl get nodes -w

# Label the new GPU node so the workspace CR's labelSelector matches
kubectl label node <new-gpu-node-name> apps=custom-llm
```

> **Note:** The daemonset toleration patches (nvidia-device-plugin, NFD, GFD) only need to be done once — they automatically apply to any new nodes that join the pool.

After the new node is ready and labeled, delete the Pending pod so it gets recreated with the correct scheduling:

```powershell
kubectl delete pod workspace-custom-llm-0 -n kaito-workspace
```

The StatefulSet will recreate the pod and schedule it on the new GPU node.

### Watch for the Pod to Become Ready

```powershell
kubectl get pods -n kaito-workspace -w | Select-String "workspace-custom-llm"
```

---

### Testing the Custom Model (SmolLM2)

#### Option A — Nginx Jump Box (In-Cluster)

**List available models:**

```powershell
kubectl exec nginx -it -- curl -s http://workspace-custom-llm.kaito-workspace/v1/models | jq
```

**Chat completions:**

```powershell
kubectl exec nginx -it -- curl -X POST http://workspace-custom-llm.kaito-workspace/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "HuggingFaceTB/SmolLM2-1.7B-Instruct",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0,
    "stream": false
  }' | jq
```

**Responses endpoint:**

```powershell
kubectl exec nginx -it -- curl -X POST "http://workspace-custom-llm.kaito-workspace/v1/responses" -H "Content-Type: application/json" -d '{
    "model": "HuggingFaceTB/SmolLM2-1.7B-Instruct",
    "input": "What is Kubernetes?",
    "max_output_tokens": 200
  }' | jq
```

#### Option B — Port-Forward (Local)

```powershell
kubectl port-forward svc/workspace-custom-llm -n kaito-workspace 8080:80
```

Then in another terminal:

**List available models:**

```powershell
curl -s http://localhost:8080/v1/models | jq
```

**Chat completions:**

```powershell
curl -s -X POST http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "HuggingFaceTB/SmolLM2-1.7B-Instruct",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0,
    "stream": false
  }' | jq
```

**Responses endpoint:**

```powershell
curl -s -X POST http://localhost:8080/v1/responses -H "Content-Type: application/json" -d '{
    "model": "HuggingFaceTB/SmolLM2-1.7B-Instruct",
    "input": "What is Kubernetes?",
    "max_output_tokens": 200
  }' | jq
```

---

## Deploying a KAITO Preset Model (DeepSeek R1 Distill Llama 8B)

Same deployment pattern as Phi-4, but using a different preset from the KAITO model repository.

> **Reminder:** With NAP disabled, make sure `instanceType` is commented out in the workspace YAML. If it's set, KAITO will error with "no ready nodes found, unable to determine GPU configuration".

### Apply the Workspace CR

```powershell
kubectl apply -f kaito_deepseek_r1_distill_llama_8b.yaml -n kaito-workspace
```

### Wait for the Third GPU Node

If the first two GPU nodes are already occupied by Phi-4 and SmolLM2, the cluster autoscaler will provision a third GPU node (max is 3). Watch for it:

```powershell
kubectl get nodes -w
```

### Label the New GPU Node

```powershell
kubectl label node <new-gpu-node-name> apps=deepseek-r1-distill-llama-8b
```

### Add Spot Toleration to the Model StatefulSet

```powershell
kubectl get statefulset -n kaito-workspace

kubectl patch statefulset workspace-deepseek-r1-distill-llama-8b -n kaito-workspace --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations/-",
    "value": {
      "key": "kubernetes.azure.com/scalesetpriority",
      "operator": "Equal",
      "value": "spot",
      "effect": "NoSchedule"
    }
  }
]'
```

### Monitor the Deployment

```powershell
kubectl get workspace -n kaito-workspace
kubectl get pods -n kaito-workspace -w | Select-String "workspace-deepseek"
```

### Testing DeepSeek R1

#### Option A — Nginx Jump Box (In-Cluster)

**List available models:**

```powershell
kubectl exec nginx -it -- curl -s http://workspace-deepseek-r1-distill-llama-8b.kaito-workspace/v1/models | jq
```

**Chat completions:**

```powershell
kubectl exec nginx -it -- curl -X POST http://workspace-deepseek-r1-distill-llama-8b.kaito-workspace/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0
  }' | jq
```

**Responses endpoint:**

```powershell
kubectl exec nginx -it -- curl -X POST "http://workspace-deepseek-r1-distill-llama-8b.kaito-workspace/v1/responses" -H "Content-Type: application/json" -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "input": "What is Kubernetes?",
    "max_output_tokens": 200
  }' | jq
```

#### Option B — Port-Forward (Local)

```powershell
kubectl port-forward svc/workspace-deepseek-r1-distill-llama-8b -n kaito-workspace 8080:80
```

Then in another terminal:

**List available models:**

```powershell
curl -s http://localhost:8080/v1/models | jq
```

**Chat completions:**

```powershell
curl -s -X POST http://localhost:8080/v1/chat/completions -H "Content-Type: application/json" -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "messages": [{"role": "user", "content": "What is kubernetes?"}],
    "max_tokens": 50,
    "temperature": 0
  }' | jq
```

**Responses endpoint:**

```powershell
curl -s -X POST http://localhost:8080/v1/responses -H "Content-Type: application/json" -d '{
    "model": "deepseek-r1-distill-llama-8b",
    "input": "What is Kubernetes?",
    "max_output_tokens": 200
  }' | jq
```

---

## Monitoring

vLLM exposes Prometheus metrics at the `/metrics` endpoint. These metrics provide detailed insights into the system's performance, resource utilization, and request processing statistics.

### Scrape Metrics Directly

```powershell
kubectl exec nginx -it -- curl http://workspace-phi-4-mini.kaito-workspace:80/metrics
```

### Set Up ServiceMonitor for Prometheus

Add the following label to your KAITO inference service so that a Kubernetes ServiceMonitor can detect it:

```powershell
kubectl label svc workspace-phi-4-mini app=phi-4-mini -n kaito-workspace
# service/workspace-phi-4-mini labeled
```

Create a ServiceMonitor resource to define the inference service endpoints and scrape the vLLM Prometheus metrics. Deploy this in the `kube-system` namespace to export metrics to the managed service for Prometheus:

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
# servicemonitor.azmonitoring.coreos.com/prometheus-kaito-monitor created
```

---

## Key Learnings and Gotchas

Things we ran into during this deployment that are worth knowing:

- **Always tolerate the Spot taint.** Every pod that needs to run on a GPU node — daemonsets, model StatefulSets, everything — needs the `kubernetes.azure.com/scalesetpriority=spot:NoSchedule` toleration. If you forget this, pods will stay Pending forever.

- **`instanceType` must be commented out when NAP is disabled.** If you set `instanceType` in the workspace CR while running in BYO node mode (`disableNodeAutoProvisioning=true`), KAITO will error with "no ready nodes found, unable to determine GPU configuration". Just comment it out — KAITO doesn't need it when you're providing the node yourself.

- **One GPU per node = one model per node.** The `Standard_NC24ads_A100_v4` SKU has a single A100 GPU. You can't run two models on the same node. Deploy a second model and the cluster autoscaler will scale up another GPU node. Make sure your `--max-count` on the node pool is high enough.

- **Label the node before or after applying the workspace CR.** KAITO uses `labelSelector.matchLabels` to find the target node. If no node has the matching label, the pod won't schedule. Labels are **case-sensitive**.

- **DaemonSet tolerations are set once.** After you patch the three daemonsets (nvidia-device-plugin, NFD worker, GFD), those tolerations apply to all GPU nodes in the pool — including new nodes that scale up later. You don't need to patch them again.

- **Delete the Pending pod after labeling a new node.** When the autoscaler provisions a new GPU node for a second/third model, the pending pod might not automatically reschedule. Delete it and the StatefulSet will recreate it with the correct scheduling.

- **PowerShell + `curl.exe` + `jq` — use the `-s` flag.** When piping `curl.exe` output to `jq` in PowerShell, the progress meter corrupts the JSON output. Always add `-s` (silent mode) to suppress it.

- **`/v1/responses` is a valid vLLM endpoint.** It uses a simpler input/output format compared to `/v1/chat/completions` and is useful for quick tests.

-
