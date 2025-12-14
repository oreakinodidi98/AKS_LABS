# Fundamentals

## Kubernetes Architecture

![Diagram](image.png)

- A container can is a lightweight, portable, and deployment of software that includes everything needed to run an application
- Azure Container Registry (ACR) which is a private registry that offers several features such as geo-replication, integration with Microsoft Entra ID, artifact streaming, and even continuous vulnerability scanning and patching
- Can use open-source tool like Draft or lean on AI tools like GitHub Copilot to help you create a Dockerfile
- Following command to create a Dockerfile for Applications: `draft create --dockerfile-only --interactive`
  - Using the --interactive flag will prompt you for the port that the application will listen on and the version to use.
  - Draft can also help create Kubernetes manifest files, but the --dockerfile-only flag tells Draft to only create the Dockerfile
- The Dockerfile is a set of instructions that tells Docker how to build the container image. The `FROM` instruction specifies the base image to use. The `ENV` instruction sets an environment variable, and the `EXPOSE` instruction tells Docker which port the application will listen on.
- Run the following command to build the container image: `docker build -t name:latest` .
- With the container image built,can now run it locally: `docker run -d -p 3000:3000 --name contoso-air name:latest`
- Can use ACR tasks to execute remote builds
  - This command will package the application source code, push it up to Azure, build the image, and save it in the registry.
  - This is another way to build images in the cloud without needing to have Docker installed locally.
  - `az acr build --registry $ACR_NAME --image name:latest . --no-wait`

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

## kubectl to interact with the cluster

- See config file: `kubectl config view --raw`
- Kubernetes Api Server: `kubectl api-resources`
- Can also use the `--recursive` flag to see all the available attributes for the resource: `kubectl explain deployment --recursive`

## Multi-container Pod design patterns (e.g. sidecar, init and others)

- Pod can contain one or more containers that share the same network namespace and storage volumes.
- You can think of a Pod as a small VM where apps can communicate with each other and share data.

### Sidecar

- The design pattern of running multiple containers in a Pod, is often referred to as the "sidecar pattern"
- useful when you have a main application container with one or more containers that provide additional functionality such as logging, monitoring, caching, networking, etc.
- Some challenges faced included the fact that the sidecar container would not be restarted if it failed, or guaranteeing that the sidecar container would be started before the main application container.
- This made it difficult to use sidecar containers for certain scenarios
- With Kubernetes v1.28 and later, Kubernetes native sidecar container support was introduced
- This allows you to run a sidecar container as an `initContainer` with the `restartPolicy: Always` attribute
- means that the sidecar container will always be restarted if it fails, and it will run before the main application container starts which addressed a lot of challenges with the previous approach of using a sidecar container

## Persistent Volumes and Persistent Volume Claims

- If you need data to persist beyond the life of a Pod, you would create a Persistent Volume (PV) which is allocatable storage within the cluster, and Persistent Volume Claim (PVC) to make a claim on the piece of storage
- In AKS, Azure CSI drivers and storage classes can dynamically provision Azure Storage resources such as Azure Managed Disks or Azure File Shares to be used as PVs.
- To see Storage classes: `kubectl get storageclasses`
- The `azurefile-csi` storage class is used to create **Azure File Shares** and the `managed-csi` storage class is used to create **Azure Managed Disks**.

## Application Deployment

- **Blue/green**: Blue/green deployment is a deployment strategy that allows you to deploy a new version of an application without downtime. The idea is to have two identical environments, one for the current version (blue) and one for the new version (green). When you are ready to deploy the new version, you switch the traffic from the blue environment to the green environment.
- command to port-forward service resource to your local machine : `echo "http://$(kubectl get svc mynginx --output jsonpath='{.status.loadBalancer.ingress[0].ip}')"`
- Command to change a manifest value `kubectl patch svc mynginx --patch '{"spec":{"selector":{"app":"nginx-green"}}}'`
- **Canary** : Canary deployment is a deployment strategy that allows you to deploy a new version of an application to a small subset of users before rolling it out to the entire user base

## Rolling updates

- History of Deployments with the revision numbers `kubectl rollout history deploy/nginx-green`
- To rollback to a previous version of the Deployment, run the `kubectl rollout undo --to-revision`

## Helm

- Helm is a package manager for Kubernetes that allows you to easily deploy and manage applications in your cluster.
- Helm uses a packaging format called charts, which are collections of files that describe a related set of Kubernetes resources.
- Command to add the aks-store-demo Helm repository to your local Helm client: `helm repo add aks-store-demo https://azure-samples.github.io/aks-store-demo`
- Command to update the Helm repository: `helm repo update`
- Often times a Helm repository will have multiple charts. Command to search for charts in the repository: `helm search repo aks-store-demo`
- Can  view the details of a chart using the `helm template` command.
  - This will render the chart templates and show you the Kubernetes resources that will be created when you install the chart
  - `helm template aks-store-demo/aks-store-demo-chart`
- To install the chart, you can use the `helm install` command.
- This will create all the resources defined in the chart and deploy the application to your cluster.
- `helm install aks-store-demo aks-store-demo/aks-store-demo-chart --namespace pets --create-namespace`
- Once the chart is installed, you can use the helm list command to see the list of releases in the cluster.
- `helm list -n pets`
- To uninstall the aks-store-demo application, you can use the `helm uninstall` command. This will delete all the resources created by the chart.
- `helm uninstall aks-store-demo -n pets`
- Finally, to remove the aks-store-demo Helm repository from your local Helm client, you can use the `helm repo remove` command.
- `helm repo remove aks-store-demo`
- `helm uninstall aks-store-demo -n pets`
- `helm repo remove aks-store-demo`
- Helm = app store for kubernetes
- Repo = adding app store
- chart = searching in app storeprview before installing = `helm template repo/chart`
- install chart = deploy app -> `helm install name repo/chart`

## Kustomize

- Kustomize is a tool that allows you to customize Kubernetes resource manifests without using templating.
- It is built into kubectl and allows you to create overlays for different environments.
- This is useful for managing different configurations for different environments such as development, staging, and production
- To use Kustomize, you need to create a `kustomization.yaml` manifest to define the resources that should be included in the overlay. 
- You can use the `kustomize build`  to build the overlay and output the Kubernetes resources
- Kustomize is another powerful tool that allows you to customize Kubernetes resource deployments.
- It's a bit more lightweight than Helm and does not require any special syntax for templating.
- This makes it a good choice for simple deployments where you don't need the full power of Helm.

## Application Observability and Maintenance

- Observability is the ability to measure and understand the internal state of a system based on the data it generates.

## Implement probes and health checks

- Probes are a way to check the health of a container and determine whether it is ready to receive traffic. 
- Kubernetes supports three types of probes: **liveness**, **readiness**, and **startup**.
- **Liveness probes** are used to periodically check if a container is running.
- **Readiness probes** are used to periodically check if a container is ready to receive traffic. This is useful for containers take a long time to start up or need to warm up before they can handle traffic.
- **Startup probes** are used to check if a container has started. Like readiness probes, this is useful for containers that take a long time to start up. Unlike readiness probes, startup probes are only run once when the container starts.

## Discover and use resources that extend Kubernetes (CRD, Operators)

- Operators are a way to extend Kubernetes to manage complex applications. They are built on** top of Custom Resource Definitions (CRDs)** and use the Kubernetes API to manage the lifecycle of the application.
- **KEDA (Kubernetes Event-Driven Autoscaler)** and **VPA (Vertical Pod Autoscaler)** are two examples of operators that are commonly used in Kubernetes.
- These open-source tools can be installed manually, but in AKS, they are available as managed add-on.

## Authentication, authorization and admission control

- **Authentication** is the process of verifying the identity of a user or ServiceAccount.
- **Authorization** is the process of determining whether a user or ServiceAccount has permission to perform a specific action on a resource
- Kubernetes supports several authentication methods with the most common being **certificate-based authentication**.
- This is the default method used by AKS. 
- When you run the `az aks get-credentials` command, it creates a kubeconfig file that contains the certificate for the AKS cluster.
- This certificate is used to authenticate to the cluster
- `kubectl config view` view kubeconfig file

kubeconfig file contains the following information:

- **clusters**: The list of clusters that are configured in the kubeconfig file. Each cluster has a name and a certificate authority (CA) certificate.
- **contexts**: The list of contexts that are configured in the kubeconfig file. Each context has a name and specifies the cluster and user to use when connecting to the cluster.
- **users**: The list of users that are configured in the kubeconfig file. Each user has a name and a certificate.

- To grant access to a user or ServiceAccount, Kubernetes has a built-in Role-Based Access Control (RBAC) system.
- RBAC is used to define roles and permissions for users and service accounts in the cluster.
- When you create a Role or ClusterRole, you define the permissions that are granted to the user or ServiceAccount.
- You can then bind the Role or ClusterRole to a user or ServiceAccount using a RoleBinding or ClusterRoleBinding.
- `kubectl get clusterroles`
- The ClusterRoles that is associated with the default cluster user is cluster-admin when you pulled down the kubeconfig file using the `az aks get-credentials` command.
- `kubectl describe clusterrole cluster-admin`

### Admission control

- In Kubernetes, admission control is a way to enforce policies on the resources that are created in the cluster.
- Admission controllers are plugins that intercept requests to the Kubernetes API server and can modify or reject the requests based on the policies that are defined.
- Historically admission control was implemented using **validating admission webhooks** which are HTTP callbacks that are called by the Kubernetes API server when a request is made to create or modify a resource.
- The webhook can then **validate the request and either accept or reject** it based on the policies that are defined.
- With Kubernetes 1.30 or later, admission control can be implemented using the Validating Admission Policy feature which is a new way to implement admission control using a declarative policy language.

## Understand requests, limits, quotas

- Kubernetes schedules containers to run on nodes in the cluster.
- But as it schedules containers, it must know how much CPU and memory each container is expected to use
- Should define requests and limits for each container in your application.
- Requests are the minimum amount of CPU and memory that the container needs to run.
- Limits are the maximum amount of CPU and memory that the container can use
- This allows Kubernetes to schedule the container on a node that has enough resources to run the container.
- Making sure the application has enough resources to run is important for performance and reliability.
- Not only that, but preventing a container from using more resources than it needs is important for cost savings.
- `kubectl top pod`  to view the resource usage of the containers in the cluster
- In AKS, you can use the **AKS Monitor** feature and use the built in **Workbooks** to get recommendations for the resource requests and limits for the containers in the cluster.
- Can use the **Vertical Pod Autoscaler (VPA)** to automatically adjust the requests and limits for the containers in the cluster.
- The **VPA** will monitor the resource usage of the containers and adjust the requests and limits over time and based on the usage patterns
- The VPA is an operator that runs in the cluster and uses the Kubernetes API to monitor the resource usage of the containers.
- It can be installed as a managed add-on in AKS
- Need to create a VPA resource that specifies the target deployment and the resource requests and limits.
- The VPA will then monitor the resource usage of the containers in the deployment and adjust the requests and limits over time
- `kubectl get vpa`

## Understand ConfigMaps

- Almost every application has settings that can be configured.
- These settings are typically stored in a configuration file or environment variables.
- In Kubernetes, you can use ConfigMaps to store these settings and make them available to the application.
- You can create a ConfigMap resource from a file or from literal values.
- The ConfigMap resource can then be mounted as a volume in the Pod or used as environment variables in the containe

## Create & consume Secrets

- Just like ConfigMaps, you can use Secrets to store sensitive information such as passwords, tokens, and SSH keys.
- Secrets are similar to ConfigMaps, but they are base64 encoded and are intended to be used for sensitive information.
- Instead of creating a Secrets resource, can use the **Azure App Config Provider** for Kubernetes to store the secrets in Azure Key Vault and use them in the application
- `kubectl create secret generic contoso-air-secrets \
--from-literal=AZURE_COSMOS_LISTCONNECTIONSTRINGURL=$MONGO_LISTCONNECTIONSTRING_URL`
- The Kubernetes Secret resource is created and the secret is stored in the cluster
- With AKS, you can store secrets in Azure Key Vault and use the Secret Store CSI driver to access the secrets in your application

## Understand ServiceAccounts

- ServiceAccounts are used to **provide an identity for applications that run in the cluster**.
- By default, Kubernetes creates a default ServiceAccount for each namespace.
- This ServiceAccount can be used by the application to authenticate to the Kubernetes API server.
- A great example of ServiceAccount usage in AKS is with the Workload Identity feature.
- Workload Identity allows you to use Microsoft Entra ID to authenticate to Azure services from the application running in the cluster
- With ServiceAccount it can be annotated with the **azure.workload.identity/client-id** annotation which maps to the **Client ID** of the **Microsoft Entra ID application**
- apply this annotation to deployment `azure.workload.identity/use: "true"`

## Services and Networking

- Every Pod in the cluster has its own IP address and can communicate with other Pods in the cluster using their IP addresses.
- As Pods are exposed via Services, discoverability and load balancing is enabled out-of-the-box so applications can reach each other using an internal DNS name.
- NetworkPolicies are used to control the traffic between Pods in the cluster.
- By default, all traffic is allowed between Pods in the same namespace.
- You can use NetworkPolicies to restrict the traffic between Pods and control which Pods can communicate with each other.
- By default, AKS clusters do not have NetworkPolicies enabled
- NetworkPolicies are a powerful way to control the traffic between Pods in the cluster.
- However, they can be complex to manage and configure

## Provide and troubleshoot access to applications via services

- In Kubernetes, a Service is a resource that provides a stable endpoint for accessing a set of Pods.
- Services are used to expose applications running in the cluster to the outside world or to other applications running in the cluster.
- For HTTP-based applications, Services might not be the best option as they are **limited to Layer 4 of the OSI model**
- They can only route traffic based on the IP address and port of the request.
- For HTTP-based applications, you will want to use an Ingress resource to expose the application to the outside world

## Use Ingress rules to expose applications

- Can use the `kubectl port-forward` command to access the applications running in the cluster
- Can use the `kubectl expose` command to create a Service resource that e**xposed a HTTP-based application** to the outside world via public IP
- Great for dev and testing
- In production, you will want to use an **Ingress resource** to expose the application to the outside world
- Ingress is a Kubernetes resource that allows you to expose your application to the outside world.
- Ingress resources are used to define rules for routing traffic to the application at **Layer 7 of the OSI model**.
- This means that you can route traffic based on the hostname and path of the request.
- The Ingress-Nginx project is a popular Ingress controller for Kubernetes. It is a powerful and flexible Ingress controller that can be used to expose your application to the outside world.
- This operator is available in AKS as a managed add-on.
- So you can simply deploy an Ingress resource and the Ingress-Nginx controller will be deployed for you.
- With AKS, the Ingress-Nginx controller is deployed as a managed add-on known as AKS App Routing.
- You can simply deploy an Ingress resource and the Ingress-Nginx controller will be deployed for you.
- The Ingress resource is considered to be a reliable yet legacy way to manage traffic in Kubernetes.
- The Gateway API is emerging as a new standard for managing traffic in Kubernetes for both Layer 4 and Layer 7 traffic.
- The **AKS App Routing add-on** does more than just deploy the Ingress-Nginx controller.
- It also provides integration with Azure DNS and Azure Key Vault to provide an end-to-end solution for exposing your application to the outside world and managing the secrets and certificates for it.