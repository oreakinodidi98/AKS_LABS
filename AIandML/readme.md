# AI and ML Workloads in Azure Kubernetes Service

## Table of Contents

- [AI and ML Workloads in Azure Kubernetes Service](#ai-and-ml-workloads-in-azure-kubernetes-service)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [The Challenge](#the-challenge)
  - [Why AKS for AI and ML?](#why-aks-for-ai-and-ml)
  - [Architecture Summary](#architecture-summary)
    - [AKS — The Foundation](#aks--the-foundation)
    - [Ray — The Engine](#ray--the-engine)
    - [KubeRay — The Translator](#kuberay--the-translator)
    - [Ray Job Spec — The Recipe](#ray-job-spec--the-recipe)
  - [Ray Cluster](#ray-cluster)
    - [What is Ray?](#what-is-ray)
    - [Ray Libraries](#ray-libraries)
    - [What is KubeRay?](#what-is-kuberay)
  - [Deployment Process](#deployment-process)
  - [Deploying a Ray Job](#deploying-a-ray-job)
    - [Ray Job Spec Fields](#ray-job-spec-fields)
    - [Resource Requirements](#resource-requirements)
    - [Monitoring the Job](#monitoring-the-job)
  - [Ray Dashboard](#ray-dashboard)
  - [BlobFuse](#blobfuse)

---

## Overview

Artificial Intelligence (AI) is changing how we solve problems. Generative AI — tools that create text, art, or music — makes applications feel far more personal and powerful. Running these workloads at scale requires a solid infrastructure platform.

This lab demonstrates how to run AI and ML workloads on **Azure Kubernetes Service (AKS)** using **Ray** and **KubeRay**.

---

## The Challenge

As AI models grow smarter, they also become harder and more expensive to manage. Key challenges include:

| Challenge | Description |
|---|---|
| **Compute power** | Training and serving models requires many machines working in parallel |
| **Integration** | AI needs to work smoothly alongside other software and data tools |
| **Efficiency** | Without the right platform, resources are wasted and operations become slow |

---

## Why AKS for AI and ML?

AKS keeps AI infrastructure organised, reliable, and easy to scale.

| Benefit | Description |
|---|---|
| **High Performance** | Provides the compute power needed to run complex AI without slowdowns |
| **Cost & Security** | Uses resources efficiently while keeping data secure |
| **Less Busywork** | Handles server management automatically — freeing teams to build features |
| **Flexibility** | Works with popular tools and workflows teams already use |

> **Bottom line:** AKS takes the heavy lifting out of managing AI infrastructure, so you can launch faster and run more reliably.

---

## Architecture Summary

### AKS — The Foundation

AKS is the infrastructure manager. It handles the health, scaling, and security of the underlying servers. If a node fails, AKS replaces it automatically. If the workload grows, AKS scales up.

### Ray — The Engine

Ray tells the AKS nodes how to work together as one distributed system. Python normally runs on a single machine — Ray unlocks it to run across hundreds of nodes at once. It includes purpose-built libraries for training, tuning, serving, and data processing.

### KubeRay — The Translator

KubeRay bridges AKS and Ray. It is a Kubernetes Operator that lives inside AKS and automates Ray cluster setup. Instead of manually configuring every Ray setting, you provide KubeRay a **Job Spec** (a YAML recipe) and it handles the rest.

### Ray Job Spec — The Recipe

A simple YAML file that defines exactly what the job should do:

- **replicas** — how many worker pods to spin up
- **NUM_WORKERS** — how many Ray tasks to run in parallel
- **CPU / Memory** — how much compute to give each worker

> **Rule of thumb:** You cannot request more resources than the nodes actually have. If pods have 3 CPUs, set `CPUS_PER_WORKER` to 2, leaving 1 CPU for system processes.

---

## Ray Cluster

### What is Ray?

Ray is a free, open-source framework (originally from UC Berkeley) that lets you take a Python program and distribute it across many machines with minimal code changes. Essentially an open-source framework for distributed computing and machine learning workloads.

### Ray Libraries

| Library | Purpose |
|---|---|
| **Ray Core** | Distributed computing primitives |
| **Ray Train** | Distributed ML model training |
| **Ray Serve** | Scalable model serving |
| **Ray Tune** | Hyperparameter tuning at scale |
| **Ray Data** | Distributed data processing |

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

This example uses:

| Pod | CPU | Memory | Role |
|---|---|---|---|
| Head pod | 1 CPU | 4 GB | Coordinates the job |
| Worker pod (x2) | 3 CPUs each | 4 GB each | Runs the training tasks |
| **Total** | **7 CPUs** | **12 GB** | Minimum node pool capacity needed |

**Key rules:**

- `NUM_WORKERS` must be <= `replicas` — one Ray actor per worker pod
- `CPUS_PER_WORKER` must be <= worker pod CPUs minus 1 (reserve 1 CPU for the system)
  - Example: 3 CPUs per pod -> set `CPUS_PER_WORKER: 2`

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

The Ray Dashboard is a web interface for real-time monitoring of Ray clusters. It shows charts, logs, and job progress — useful when training jobs run for hours or days.

**Accessing the dashboard:**

The Ray head service runs on port **8265** by default. To expose it via the AKS ingress controller (which uses port 80), a **service shim** is created:

- A service shim is a lightweight Kubernetes `Service` that listens on port **80** and forwards traffic to port **8265** on the Ray head pod
- An `Ingress` resource then routes public HTTP traffic to the shim

```bash
# Create the service shim
kubectl expose service <ray-head-service> --type=NodePort -n kuberay --port=80 --target-port=8265 --name=ray-dash

# Get the public IP of the ingress controller
kubectl get svc nginx -n app-routing-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Access the dashboard at: `http://<public-ip>/`

## BlobFuse

- Can also configure and deploy a Ray cluster on Azure Kubernetes Service (AKS) using KubeRay, with BlobFuse providing scalable storage
- When deployed on Azure Kubernetes Service (AKS), Ray enables scalable tuning, training, and inference across multiple nodes.
- Integrating BlobFuse as a persistent storage backend allows Ray jobs to efficiently read and write large datasets, which is critical for tuning workloads that require rapid access to training data, intermediate results, and model checkpoints.
- High throughput from BlobFuse is essential for tuning jobs because these workloads often involve many parallel tasks, each reading and writing data simultaneously
- BlobFuse provides POSIX-compliant, high-performance access to Azure Blob Storage, minimizing I/O bottlenecks and ensuring that distributed Ray tasks can complete faster.
- This results in more efficient resource utilization and accelerates the overall tuning process
- This solution leverages KubeRay to orchestrate Ray clusters on AKS, with BlobFuse providing scalable and performant storage.
- This architecture ensures high throughput for distributed tuning jobs, allowing multiple Ray workers to efficiently read and write data in parallel, which accelerates model training and hyperparameter optimization