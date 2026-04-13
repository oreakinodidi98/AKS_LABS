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
  - [Integrate with Azure Monitor](#integrate-with-azure-monitor)
  - [BlobFuse Storage Integration](#blobfuse-storage-integration)
  - [Ray Cluster Configuration](#ray-cluster-configuration)
  - [Auto-scaling and Resource Management](#auto-scaling-and-resource-management)
    - [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler)
    - [Cluster Autoscaler](#cluster-autoscaler)
  - [Ray Data: Distributed Data Processing](#ray-data-distributed-data-processing)
    - [Ray Data Architecture](#ray-data-architecture)
      - [Why Ray Data is valuable](#why-ray-data-is-valuable)
    - [Demo Data Processing Pipeline + Job](#demo-data-processing-pipeline--job)
  - [Best Practices](#best-practices)
    - [Resource Optimisation](#resource-optimisation)
    - [Performance Tuning](#performance-tuning)
    - [Security](#security)
  - [Key Takeaways](#key-takeaways)

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

The Ray Dashboard is a web UI for real-time monitoring of Ray clusters — useful when training jobs run for hours or days. The Ray dashboard provides real-time insights into cluster performance.

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

## Integrate with Azure Monitor

Set up monitoring with Prometheus for metrics collection and Grafana for visualisation, specifically configured for Ray workloads.

| Component | Description |
|---|---|
| **Prometheus Configuration** | Automatically discovers Ray head and worker services |
| **Grafana Dashboard** | Pre-configured with Ray-specific visualisations |
| **Service Discovery** | Kubernetes-native service discovery for dynamic scaling |
| **Alert Rules** | Built-in alerting for common Ray issues |

Apply the monitoring configuration:

```bash
kubectl apply -f ray-monitoring.yaml
```

Access the dashboards:

```bash
# Prometheus
kubectl port-forward -n $RAY_NAMESPACE deployment/ray-prometheus 9090:9090
# → http://localhost:9090

# Grafana
kubectl port-forward -n $RAY_NAMESPACE service/ray-grafana-svc 3000:3000
# → http://localhost:3000
```

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

| Feature | Detail |
|---|---|
| **Head node** | Dashboard (port 8265) and client API (port 10001) access |
| **Worker group** | Scalable with 1–5 replicas |
| **Resources** | Requests and limits configured for production stability |
| **Volumes** | `emptyDir` mounts for Ray logs and temporary files |

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

## Ray Data: Distributed Data Processing

Can be used to process a large synthetic dataset across multiple nodes, demonstrating how Ray can handle ETL workloads that exceed single node memory capacity

| | Traditional Approach | Ray Data |
|---|---|---|
| **Processing** | Single-node, limited by memory | Automatic distribution across cluster nodes |
| **Data Partitioning** | Manual partitioning and distribution | Built-in fault tolerance and retry mechanisms |
| **Scaling** | Complex coordination between nodes | Seamless scaling from single-node to multi-node |
| **API** | Difficult resource management | Unified API for various data sources and formats |

### Ray Data Architecture

Ray Data provides a distributed data processing framework that automatically:

```
┌─────────────────────────────────────────────────────────────┐
│                    Ray Data Pipeline                        │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │   Data      │    │ Transform   │    │   Output    │      │
│  │  Creation   │──▶│ Operations  │──▶ │  Results    │      │
│  │             │    │             │    │             │      │
│  └─────────────┘    └─────────────┘    └─────────────┘      │
│                                                             │
│  Distributed across Ray cluster nodes                       │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐    │
│  │  Node 1   │ │  Node 2   │ │  Node 3   │ │  Node 4   │    │
│  │ Worker    │ │ Worker    │ │ Worker    │ │ Worker    │    │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘    │
└─────────────────────────────────────────────────────────────┘
```

#### Why Ray Data is valuable

| Feature | Description |
|---|---|
| **Automatic Parallelisation** | No manual data partitioning required |
| **Memory Efficiency** | Streams data without loading everything into memory |
| **Fault Tolerance** | Automatic retry and recovery from node failures |
| **Flexible Transformations** | Rich set of operations for filtering, grouping, and aggregation |

### Demo Data Processing Pipeline + Job

The Python file demonstrates real-world ETL operations like data generation, filtering, aggregation, and transformation.

The Kubernetes Job configuration runs the data processing pipeline within the cluster, connecting to the Ray cluster for distributed execution. This shows it is possible to integrate Ray workloads with Kubernetes job management.

**When deployed:**

- Kubernetes creates a job pod with the processing script
- The job connects to your existing Ray cluster
- Ray Data automatically distributes work across available nodes
- Processing results are collected and displayed

1. Create a ConfigMap with the processing script:
   ```bash
   kubectl create configmap ray-data-processing-script \
     --from-file=data_processing.py -n kuberay
   ```

2. Apply the processing job:
   ```bash
   kubectl apply -f data-processing-job.yaml
   ```

3. Monitor the job progress:
   ```bash
   kubectl logs -n $RAY_NAMESPACE job/ray-data-processing -f
   ```

---

## Best Practices

### Resource Optimisation

| Practice | Why it matters |
|---|---|
| **Right-size containers** | Match CPU/memory requests and limits to actual usage — avoid over-provisioning |
| **Use node affinity** | Pin the Ray head pod to a dedicated node so it isn't competing for resources |
| **Separate workload pools** | Use different node pools for compute-heavy vs. memory-heavy jobs |

### Performance Tuning

| Practice | Why it matters |
|---|---|
| **Tune batch sizes** | Larger batches improve throughput but increase latency — find the right balance |
| **Balance task granularity** | Too many tiny tasks add scheduling overhead; too few waste parallelism |
| **Monitor the object store** | Ray's Plasma store holds shared data — watch its usage to avoid spills to disk |

### Security

| Practice | Why it matters |
|---|---|
| **Network policies** | Restrict pod-to-pod traffic so only Ray components can communicate |
| **RBAC** | Grant least-privilege access to namespaces and cluster resources |
| **Kubernetes Secrets** | Store credentials and tokens as Secrets — never hard-code them in manifests |

---

## Key Takeaways

| Takeaway | Detail |
|---|---|
| **Minimal code changes** | Ray turns single-machine Python into distributed applications with a few annotations |
| **Seamless K8s integration** | KubeRay manages Ray clusters declaratively — deploy, scale, and upgrade via YAML |
| **Auto-scaling at two levels** | Combine Ray's built-in scaling with Kubernetes HPA and Cluster Autoscaler |
| **Production-ready** | Built-in monitoring, fault tolerance, and resource management out of the box |
| **Works with your stack** | Integrates with PyTorch, TensorFlow, Azure Monitor, BlobFuse, and more |