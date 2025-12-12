# AKS_LABS

## Startup

- az aks start --resource-group myresourcegroup489086251 --name myakscluster489086251
- Set-Alias k kubectl
- kubectl create namespace pets
- kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/refs/heads/main/aks-store-quickstart.yaml -n pets
- kubectl get all -n pets
- kubectl get svc store-front -n pets

## Kubernetes workload resources

Kubernetes is a container orchestrator, but it doesn't run containers directly. Instead, it runs containers inside a resource known as a **Pod**. **A Pod is the smallest deployable unit in Kubernetes**. It is a logical host for one or more containers which runs your application.

But even then, a Pod is not what you want to deploy because a Pod is not a long-lived resource. Meaning, if a Pod dies, Kubernetes will not attempt to restart it.

Instead, you need to use a workload resource to manage Pods for you. There are several different types of workload resources in Kubernetes that manages Pods, each with its own use case and knowing when to use each is important.

The most common types of workload resources are:

- **Deployment** resource is a declarative way to manage a set of Pods. It in turn creates a ReplicaSet resource to manage the Pods. A Deployment is used for stateless applications and is the most common way to deploy applications in Kubernetes.
- **ReplicaSet** resource is a low-level resource that is used to manage a set of Pods. It is used to ensure that a specified number of pod replicas are running at any given time. A ReplicaSet is mostly used by the Deployment resource to manage the Pods. You typically won't use a ReplicaSet directly, but it's important to understand how it works.
- **StatefulSet** resource is used to manage stateful applications. It is used for applications that require stable, unique network identifiers and stable storage. A StatefulSet is used for applications that require persistent storage and stable network identities, such as databases. A stateful set is a workload resource that is used to manage stateful applications. It is used for applications that require stable, unique network identifiers and stable storage.
- **DaemonSet** resource is often used to ensure that a copy of a Pod is running on all nodes in the cluster, such as logging or monitoring agents.
- **Job** resource is a workload resource that is used to run a batch job. These are applications that need to run to completion, such as data processing jobs.
- **CronJob** resource is a workload resource that is used to run a batch job on a schedule, such as backups or report generation.

The workload resource that you request are reconciled by various controllers in the Kubernetes control plane. For example, when you create a Deployment, the Deployment controller will create a ReplicaSet and the ReplicaSet controller will create the Pods.

When you submit a resource through the Kubernetes API server, the desired state is stored in etcd and controllers are responsible for ensuring that the actual state matches the desired state. This is known as the reconciliation loop.

Each resource type is it's own API in Kubernetes and has it's own set of properties which you set in a manifest file written in YAML or JSON. Once the manifest file is created, you can use the kubectl CLI to create the resource in the cluster.