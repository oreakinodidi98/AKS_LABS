# AI and ML Workloads on Azure Kubernetes Service

## Table of Contents

- [AI and ML Workloads on Azure Kubernetes Service](#ai-and-ml-workloads-on-azure-kubernetes-service)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [The Challenge](#the-challenge)
  - [Why AKS for AI and ML?](#why-aks-for-ai-and-ml)
  - [Architecture Summary](#architecture-summary)
  - [Ray Cluster](#ray-cluster)
    - [What is Ray?](#what-is-ray)
    - [Ray Libraries](#ray-libraries)
    - [Ray Train](#ray-train)
      - [Distributed Training Architecture](#distributed-training-architecture)
      - [Training Script](#training-script)
      - [Deploying the Training Script on AKS](#deploying-the-training-script-on-aks)
    - [Model Serving with Ray Serve](#model-serving-with-ray-serve)
      - [Ray Serve Architecture](#ray-serve-architecture)
      - [Deploying the Serving Application on AKS](#deploying-the-serving-application-on-aks)
    - [What is KubeRay?](#what-is-kuberay)
  - [Deployment Process](#deployment-process)
  - [Deploying a Ray Job](#deploying-a-ray-job)
    - [Ray Job Spec Fields](#ray-job-spec-fields)
    - [Resource Requirements](#resource-requirements)
    - [Monitoring the Job](#monitoring-the-job)
  - [Ray Dashboard](#ray-dashboard)
  - [BlobFuse Storage Integration](#blobfuse-storage-integration)
  - [Ray Cluster Configuration](#ray-cluster-configuration)
  - [Auto-scaling and Resource Management](#auto-scaling-and-resource-management)
    - [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler)
    - [Cluster Autoscaler](#cluster-autoscaler)

---

## Overview

Artificial Intelligence (AI) is changing how we solve problems. Generative AI — tools that create text, art, or music — makes applications feel far more personal and powerful. Running these workloads at scale requires a solid infrastructure platform.

This lab demonstrates how to run AI and ML workloads on **Azure Kubernetes Service (AKS)** using **Ray** and **KubeRay**.

---

## The Challenge

As AI models grow smarter, they also become harder and more expensive to manage:

| Challenge | Description |
|---|---|
| **Compute power** | Training and serving models requires many machines working in parallel |
| **Integration** | AI needs to work smoothly alongside other software and data tools |
| **Efficiency** | Without the right platform, resources are wasted and operations become slow |

---

## Why AKS for AI and ML?

AKS keeps AI infrastructure organised, reliable, and easy to scale:

| Benefit | Description |
|---|---|
| **High Performance** | Provides the compute power needed to run complex AI without slowdowns |
| **Cost & Security** | Uses resources efficiently while keeping data secure |
| **Less Busywork** | Handles server management automatically — freeing teams to build features |
| **Flexibility** | Works with popular tools and workflows teams already use |

> **Bottom line:** AKS takes the heavy lifting out of managing AI infrastructure, so you can launch faster and run more reliably.

---

## Architecture Summary

| Component | Role |
|---|---|
| **AKS** | Infrastructure manager — handles health, scaling, and security of underlying nodes. Automatically replaces failed nodes and scales on demand. |
| **Ray** | Distributed compute engine — allows Python workloads to run across hundreds of nodes at once, with built-in libraries for training, tuning, serving, and data processing. |
| **KubeRay** | Kubernetes Operator that bridges AKS and Ray — automates Ray cluster setup from a declarative YAML spec. |
| **Ray Job Spec** | A YAML file defining what the job does: replicas, worker count, and CPU/memory per worker. |

> **Rule of thumb:** You cannot request more resources than the nodes have. If pods have 3 CPUs, set `CPUS_PER_WORKER` to 2, leaving 1 CPU for system processes.

---

## Ray Cluster

### What is Ray?

Ray is a free, open-source framework (originally from UC Berkeley) for distributed computing and machine learning. It lets you take a Python program and distribute it across many machines with minimal code changes.

### Ray Libraries

| Library | Purpose |
|---|---|
| **Ray Core** | Distributed computing primitives |
| **Ray Train** | Distributed ML model training across multiple machines |
| **Ray Serve** | Scalable model serving and inference |
| **Ray Tune** | Hyperparameter tuning at scale |
| **Ray Data** | Distributed data processing |

---

### Ray Train

Ray Train distributes model training across multiple machines with minimal code changes, dramatically reducing training time and enabling larger models and datasets.

#### Distributed Training Architecture

**Single-machine training (before):**

```
[Data] → [Single GPU/CPU] → [Model] → [Save Model]
          (limited resources)
```

**Distributed training with Ray Train (after):**

```
                          ┌─ [Worker 1: GPU/CPU] ─┐
[Data] → [Coordinator] ──┼─ [Worker 2: GPU/CPU] ──┼─ [Gradient Sync] → [Updated Model]
                          └─ [Worker N: GPU/CPU] ─┘
```

**Key benefits:**

| Benefit | Description |
|---|---|
| **Faster Training** | Parallel processing across multiple workers |
| **Scalability** | Add more workers as needed |
| **Automatic Coordination** | Ray handles data distribution and gradient synchronisation |
| **Fault Tolerance** | Training continues if individual workers fail |
| **Resource Management** | Configurable CPU/GPU allocation per worker |

#### Training Script

`distributed_training.py` demonstrates the shift from single-node to distributed training. It:

- Defines a CNN model — a simple but effective MNIST classifier
- Configures Ray Train — sets up the distributed training environment
- Handles data distribution — automatically shards data across workers
- Coordinates training — synchronises gradients and model updates
- Reports progress — provides metrics and logging across all workers

#### Deploying the Training Script on AKS

> **Before:** Single-machine training uses only one node's resources.  
> **After:** Training is distributed across multiple Ray workers using the full cluster capacity.

1. Deploy the Ray cluster into the `kuberay` namespace:
   ```bash
   kubectl apply -f ./raycluster/ray-cluster.yaml
   ```

2. Create a ConfigMap with the training script:
   ```bash
   kubectl create configmap training-script \
     --from-file=./raytraining/distributed_training.py \
     -n kuberay
   ```

3. Deploy the training job:
   ```bash
   kubectl apply -f training-job.yaml
   ```

4. Monitor job progress:
   ```bash
   kubectl get jobs -n kuberay -w
   ```

5. View training logs:
   ```bash
   kubectl logs -n kuberay job/ray-distributed-training -f
   ```

6. Watch Ray cluster utilisation via the dashboard:
   ```bash
   kubectl port-forward -n kuberay service/raycluster-ml-head-svc 8265:8265
   ```
   Then open http://localhost:8265.

**The Ray dashboard shows:**

- **Multiple Workers** — active workers participating in training
- **Resource Utilisation** — CPU/GPU usage across nodes
- **Gradient Synchronisation** — workers coordinating model updates
- **Speed Improvement** — faster epoch completion vs. single-node training

---

### Model Serving with Ray Serve

Ray Serve deploys a trained model as a scalable, production-ready inference service on AKS.

**Challenges it solves:**

- Handling varying request loads (1 to 1000s of requests/second)
- Managing model loading and memory efficiently
- Providing reliable HTTP REST APIs with error handling
- Scaling automatically based on demand

#### Ray Serve Architecture

**Traditional model serving:**

```
[Client Request] → [Single Server] → [Model] → [Response]
                   (limited by single server resources)
```

**Distributed serving with Ray Serve:**

```
                                    ┌─ [Worker 1: Model Copy] → [Response]
[Clients] → [HTTP Proxy] → [Controller] ─┼─ [Worker 2: Model Copy] → [Response]
                                    └─ [Worker N: Model Copy] → [Response]
```

**Key benefits:**

| Benefit | Description |
|---|---|
| **Auto-scaling** | Scales replicas based on request load |
| **Load Balancing** | Distributes requests across workers |
| **Resource Efficiency** | Shares model weights across replicas |
| **Fault Tolerance** | Continues serving if individual workers fail |

#### Deploying the Serving Application on AKS

The serving application is in `simple_serving.py`. It loads and caches the trained model, handles multiple input formats, exposes a REST API, and includes proper error handling.

> **Before:** The model exists only in the training environment.  
> **After:** The model serves real-time inference requests through a scalable HTTP API.

1. Create a ConfigMap with the serving code:
   ```bash
   kubectl create configmap serving-script \
     --from-file=./raytraining/simple_serving.py \
     -n kuberay
   ```

2. Apply the serving deployment and service:
   ```bash
   kubectl apply -f serving-deployment.yaml
   ```

3. Wait for the deployment to be ready:
   ```bash
   kubectl get pods -n kuberay -l app=ray-serve-mnist -w
   ```

4. Check deployment logs:
   ```bash
   kubectl logs -n kuberay deployment/ray-serve-mnist --tail=20
   ```

5. Port-forward and test the endpoint:
   ```bash
   kubectl port-forward -n kuberay service/ray-serve-mnist-svc 8000:8000
   ```
   Then open http://localhost:8000.

---

### What is KubeRay?

KubeRay is an open-source Kubernetes operator for deploying and managing Ray clusters on Kubernetes. It:

- Automates deployment, scaling, and monitoring of Ray clusters
- Uses Kubernetes custom resources to define Ray clusters declaratively
- Makes Ray clusters manageable alongside other Kubernetes workloads

---

## Deployment Process

1. **Provision AKS infrastructure** using Terraform
2. **Install KubeRay** via Helm onto the AKS cluster
3. **Submit a Ray Job** YAML manifest to train a PyTorch model on the MNIST dataset using CNNs
4. **Monitor the job** via logs and the Ray Dashboard

---

## Deploying a Ray Job

To run a training job, submit a **Ray Job spec** (YAML file) to the KubeRay operator. The spec defines the Docker image, the command to run, and how many resources to allocate.

### Ray Job Spec Fields

| Field | Location in YAML | What it does |
|---|---|---|
| `replicas` | `workerGroupSpecs` | Number of worker pods to schedule |
| `NUM_WORKERS` | `runtimeEnvYAML` | Number of Ray actors (tasks) to launch |
| `CPUS_PER_WORKER` | `runtimeEnvYAML` | CPUs available to each Ray actor |

### Resource Requirements

| Pod | CPU | Memory | Role |
|---|---|---|---|
| Head pod | 1 CPU | 4 GB | Coordinates the job |
| Worker pod × 2 | 3 CPUs each | 4 GB each | Runs the training tasks |
| **Total** | **7 CPUs** | **12 GB** | Minimum node pool capacity needed |

**Key rules:**

- `NUM_WORKERS` must be ≤ `replicas` — one Ray actor per worker pod
- `CPUS_PER_WORKER` must be ≤ worker pod CPUs minus 1 (reserve 1 CPU for the system)

### Monitoring the Job

Check job status:
```bash
kubectl get rayjob -n kuberay
```

View job logs:
```bash
kubectl logs -n kuberay <pod-name>
```

---

## Ray Dashboard

The Ray Dashboard is a web UI for real-time monitoring of Ray clusters — useful when training jobs run for hours or days.

The Ray head service runs on port **8265** by default. To expose it via the AKS ingress controller (port 80), a **service shim** is created: a lightweight `Service` that listens on port 80 and forwards traffic to port 8265 on the Ray head pod. An `Ingress` resource then routes public HTTP traffic to the shim.

**Dashboard panels:**

| Panel | What it shows |
|---|---|
| Cluster Overview | Head and worker node status and resource allocation |
| Resource Utilisation | Real-time CPU, memory, and network usage |
| Running Jobs | Active and completed jobs with execution details |
| Actor & Task Details | Task queues, execution times, and failures |
| Log Streaming | Real-time logs from head and worker nodes |
| Performance Metrics | Throughput, latency, and error rates |

**Setup:**

```bash
# Create the service shim
kubectl expose service <ray-head-service> \
  --type=NodePort -n kuberay \
  --port=80 --target-port=8265 \
  --name=ray-dash

# Get the public IP of the ingress controller
kubectl get svc nginx -n app-routing-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Access the dashboard at `http://<public-ip>/`.

---

## BlobFuse Storage Integration

BlobFuse can be used as a persistent storage backend for Ray clusters on AKS, providing scalable, high-throughput access to Azure Blob Storage for training data, model checkpoints, and intermediate results.

**Why BlobFuse for Ray workloads:**

- Provides POSIX-compliant access to Azure Blob Storage, minimising I/O bottlenecks
- High throughput is essential for tuning jobs — many parallel tasks read and write data simultaneously
- Multiple Ray workers can read and write data in parallel, accelerating training and hyperparameter optimisation
- Results in more efficient resource utilisation and faster overall job completion

---

## Ray Cluster Configuration

The base Ray cluster (`ray-cluster.yaml`) includes a head node for coordination and worker nodes for computation.

**Key configuration features:**

- Ray head node with dashboard (port 8265) and client API (port 10001) access
- Scalable worker group with 1–5 replicas
- Resource requests and limits for production stability
- `emptyDir` volume mounts for Ray logs and temporary files

---

## Auto-scaling and Resource Management

Ray on AKS can automatically scale based on workload demands using two complementary mechanisms: Horizontal Pod Autoscaler (HPA) for pod-level scaling and Cluster Autoscaler for node-level scaling.

### Horizontal Pod Autoscaler

HPA automatically scales Ray worker pods based on CPU and memory utilisation metrics.

**HPA configuration features:**

| Feature | Description |
|---|---|
| CPU & Memory Metrics | Monitors both CPU and memory utilisation |
| Scaling Behaviour | Controlled scale-up and scale-down policies |
| Replica Bounds | Configurable minimum and maximum replica counts |
| Stabilisation Window | Prevents rapid scaling fluctuations |

1. Verify the metrics server is running:
   ```bash
   kubectl get deployment metrics-server -n kube-system
   ```

2. Apply the HPA configuration:
   ```bash
   kubectl apply -f hpa.yaml
   ```

3. Monitor HPA status:
   ```bash
   kubectl get hpa -n kuberay -w
   ```

### Cluster Autoscaler

Cluster Autoscaler adds or removes AKS nodes based on pending pod demand.

1. Enable Cluster Autoscaler on the node pool:
   ```bash
   az aks update \
     --resource-group $RESOURCE_GROUP \
     --name $CLUSTER_NAME \
     --enable-cluster-autoscaler \
     --min-count 3 \
     --max-count 10
   ```

2. Verify the autoscaler is running:
   ```bash
   kubectl get pods -n kube-system | grep cluster-autoscaler
   ```