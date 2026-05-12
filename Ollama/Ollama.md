# Deploying Ollama on Kubernetes

> Run large language models on your cluster the same way you run any other workload — GPU-aware, and ready for your team.

---

## Prerequisites

Before running any of the deployments or scripts in this demo, make sure you have the following:

| Requirement | Details |
|---|---|
| **Azure CLI** | `az` installed and authenticated (`az login`) |
| **kubectl** | Configured to talk to your AKS cluster (`az aks get-credentials`) |
| **AKS Cluster** | A running AKS cluster — GPU node pool required for Stages 3–5 |
| **Node CPU** | Minimum **2 vCPU** per Ollama pod (4 vCPU recommended) — models run inference on CPU if no GPU is available |
| **Node Memory** | Minimum **12 GiB allocatable** on the target node — a 7B/8B model needs ~6–7 GiB at runtime, plus OS and kubelet overhead. Set `resources.limits.memory` to at least **12Gi** |
| **Storage** | **100 GiB PVC** (`managed-csi`) — model weights are large (8B ≈ 4.7 GB on disk). Use `ReadWriteOnce` for single-replica; `ReadWriteMany` (e.g. Azure Files) for multi-replica |
| **Python 3.10+** | Required to run `CallApi.py` |
| **pip packages** | `requests` (required), `openai` (optional — for OpenAI-compatible endpoint) |
| **Kubernetes namespace** | Create the target namespace before deploying: `kubectl create namespace ollama` |
| **Helm** *(optional)* | Only if deploying ArgoCD from scratch |

Install the Python dependencies:

```bash
pip install requests
# Optional: for OpenAI-compatible endpoint
pip install openai
```

---

## Why Ollama

Ollama turns running a large language model into something as simple as pulling a container image. Simplified — it's a **free, self-hosted alternative to ChatGPT**. It handles model downloads, quantization, and serving behind a clean REST API — no ML platform expertise required.

You run your own LLM models on your own hardware. Useful if you have **privacy concerns** or have your own homelab. Very popular open-source project with models comparable to ChatGPT. Caveat — if not running on GPUs, it's not as fast.

**vLLM** is built for maximum throughput in production inference pipelines. **Ollama** is built for ease of use. If your goal is internal tools, dev environments, or giving your team LLM capabilities without the overhead of a full ML serving stack — Ollama is the right choice.

---

## What This Guide Covers

This guide walks through deploying Ollama on Kubernetes, including:

- **Model Deployment** — downloading, serving, and swapping models
- **GPU configuration** — scheduling onto GPU nodes and setting resource limits
- **Running in Docker** — simple local setup

---

## Using Docker

```bash
docker run -it --name ollama -p 11434:11434 ollama/ollama
```

> **Important:** The Ollama container is a **framework** — it doesn't include any models out of the box. You need to download them separately after starting the container.

Exec into the running container and pull a model:

```bash
docker exec -it ollama ollama run llama3.2
```

### The Problem with `exec`

This pattern **doesn't scale** for Kubernetes or enterprise teams. Every time a pod spins up, you can't just exec into it and manually pull models — that's a non-starter.

### Workarounds

There are a few ways to handle model loading without manual intervention:

1. **Bake models into a custom image** — build a new image with the models pre-installed. Works, but creates **very large images** (7B model ≈ 4GB+).

2. **Mount a persistent volume** — store models on a **PVC** so you only download them once. New pods pick up the existing cache on startup.

3. **Use the Ollama API to pull models** — Ollama exposes a `/api/pull` endpoint. Hit it after the pod starts:

```bash
curl http://localhost:11434/api/pull -d '{
    "name": "llama3.2"
}'
```

4. **Sidecar with a postStart hook** — you might think to use an init container to run the curl command, but init containers run **before** the main container starts — so there's no Ollama server to talk to yet. The fix is to add a **sidecar container** with a `lifecycle.postStart` hook that curls the Ollama API to pull models when the pod first comes up. This is what `DeploySimple.yaml` does.

### Gotchas

> These will bite you in production if you're not aware of them.

**postStart timeout** — The postStart hook must complete within `terminationGracePeriodSeconds` (default **30s**). If you're pulling multiple large models — say `llama3.1:8b`, `mistral:7b`, `codellama:13b`, and `nomic-embed-text` — that's **30GB+ of downloads**. There's no way that finishes in 30 seconds. The result: `FailedPostStartHook` → `CrashLoopBackOff`. For multi-model pulls, use a **Job** or script that runs *after* the pod is healthy instead.

**RWO PVC with multiple replicas** — If your PVC is set to `ReadWriteOnce`, only **one node** can mount it. With `replicas: 3`, the remaining pods will sit in `Pending` or `ContainerCreating` forever. Switch to `ReadWriteMany` (e.g. Azure Files) if you need multi-replica access to the same model cache.

---

## Querying Ollama

Ollama uses port **11434** by default. To reach it from outside the cluster, expose the service with a **port-forward**:

```bash
kubectl port-forward svc/ollama 8000:11434 -n ollama
```

Once a model is loaded, query it with:

```bash
curl http://localhost:8000/api/generate -d '{
    "model": "llama3.1:8b",
    "prompt": "in exactly 12 words or less explain why the sky is blue.",
    "stream": false
}'
```

Pipe through `jq` to extract just the response text:

```bash
curl http://localhost:8000/api/generate -d '{
    "model": "llama3.1:8b",
    "prompt": "in exactly 12 words or less explain why the sky is blue.",
    "stream": false
}' | jq -r .response
```

---

## Troubleshooting

Things break — here's how to find out why.

### Pod Not Starting

Check pod status and events:

```bash
kubectl get pods -n ollama -o wide
kubectl describe pod <pod-name> -n ollama
```

Common failures from `describe`:

| Event | Cause | Fix |
|---|---|---|
| `Insufficient memory` | Node doesn't have enough allocatable memory for the pod's `requests.memory` | Lower the request, or use a larger node SKU |
| `Insufficient cpu` | Same — not enough CPU | Lower the CPU request or scale the node pool |
| `FailedScheduling` (PVC) | RWO PVC is mounted on another node | Delete the old pod first, or switch to `Recreate` strategy |
| `FailedPostStartHook` | Sidecar postStart took longer than `terminationGracePeriodSeconds` | Pull fewer models, or use a post-deploy Job instead |

### Model Won't Load — "requires more system memory"

Ollama reports available memory *inside* its cgroup, not the full node. If you see:

```
{"error":"model requires more system memory (6.3 GiB) than is available (3.4 GiB)"}
```

The container's **memory limit** is too low. Check current limits:

```bash
kubectl get pod -n ollama -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.containers[*]}  {.name}: cpu={.resources.limits.cpu} mem={.resources.limits.memory}{"\n"}{end}{end}'
```

Also reduce `OLLAMA_NUM_PARALLEL` — each parallel slot reserves memory. For an 8B model on CPU nodes, use:

```yaml
resources:
  requests:
    cpu: "2"
    memory: 4Gi
  limits:
    cpu: "4"
    memory: 12Gi
env:
  - name: OLLAMA_NUM_PARALLEL
    value: "1"
```

### Port-Forward Issues

Check the service exists and has endpoints:

```bash
kubectl get svc -n ollama
kubectl get endpoints ollama -n ollama
```

If endpoints are empty, the pod isn't ready or the selector labels don't match.

Verify port-forward is running and bound to the right port:

```bash
kubectl port-forward svc/ollama 8000:11434 -n ollama
```

If the port is already in use:

```bash
# Check what's holding the port
netstat -ano | findstr :8000

# Or use a different local port
kubectl port-forward svc/ollama 9000:11434 -n ollama
```

### Networking — Checking Connectivity from Inside the Cluster

Spin up a temporary debug pod to test connectivity to the Ollama service:

```bash
kubectl run -it --rm debug --image=curlimages/curl -n ollama -- sh
```

From inside the debug pod:

```bash
# Hit the Ollama service by its DNS name
curl http://ollama.ollama.svc.cluster.local:11434

# Pull a model
curl http://ollama.ollama.svc.cluster.local:11434/api/tags

# Test a query
curl http://ollama.ollama.svc.cluster.local:11434/api/generate -d '{
    "model": "llama3.1:8b",
    "prompt": "hello",
    "stream": false
}'
```

If DNS doesn't resolve, check CoreDNS is running:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

### Node Resource Pressure

Check actual resource usage across nodes:

```bash
kubectl top nodes
kubectl top pods -n ollama
```

Check what's allocated vs. what's available on the node running the Ollama pod:

```bash
kubectl describe node <node-name> | Select-String -Pattern "Allocated resources" -Context 0,12
```

### PVC / Storage Issues

Check PVC status and binding:

```bash
kubectl get pvc -n ollama
kubectl describe pvc ollama-data -n ollama
```

| PVC Status | Meaning | Fix |
|---|---|---|
| `Bound` | Healthy — PV is attached | — |
| `Pending` | No PV available or access mode mismatch | Check `storageClassName` exists and access mode matches |
| `Lost` | PV was deleted while PVC still references it | Delete and recreate the PVC |