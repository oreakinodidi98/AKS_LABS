# Kubernetes Architecture

These notes cover how Kubernetes runs containers across a cluster and how users reach
an application.

## Context

| Concept | Description |
| --- | --- |
| Objective | Run and orchestrate containers. |
| Cluster | A group of virtual machines or physical servers, called nodes. |
| Node | A machine in the cluster where application containers run. |
| Desired state | A declarative configuration, often provided in a YAML file, that describes what should run. |
| Container runtime | Software on a node that runs containers, such as containerd or CRI-O. |

## How a deployment works

Developers use `kubectl`, the Kubernetes command-line tool, to send requests to the
control plane. Kubernetes then works to make the cluster match the desired state.

```text
Developer
    │
    ▼
kubectl (CLI; can submit YAML configuration)
    │
    ▼
Control plane
    │ schedules and manages application pods
    ▼
Worker nodes
    │
    ▼
Container runtime → Containers
```

The control plane is the brain of Kubernetes. It manages deployments and coordinates
which containers run on which worker nodes, so developers do not need to access nodes
directly to run containers.

## Control plane components

| Component | Role |
| --- | --- |
| API server | Receives requests to the Kubernetes API. |
| etcd | Stores the cluster's configuration and state as key-value data. |
| Scheduler | Chooses nodes for pods to run on. |
| Controller manager | Helps keep the cluster in the desired state, including by managing deployments. |
| Cloud controller manager | Provisions and manages resources from the cloud provider. |

## Worker node components

| Component | Role |
| --- | --- |
| Kubelet | Receives instructions from the control plane and makes sure containers are running on the node. |
| Container runtime | Runs containers on the node. Kubernetes uses containerd or CRI-O; Docker images can run here. |

## How users reach an application

An application may have multiple instances running in containers across nodes. A load
balancer distributes incoming requests to those instances. The cloud provider can
provision this resource for the cluster.

```text
Users
  │ requests
  ▼
Load balancer
  │ distributes traffic
  ▼
Application instances in containers
  │ run on
  ▼
Worker nodes in the cluster
```

| Cloud provider | Managed Kubernetes service |
| --- | --- |
| Azure | AKS |
| Google Cloud | GKE |
| Amazon Web Services | EKS |

Cloud providers can also offer managed resources, such as disks for persistent
application data, including database or file data.
