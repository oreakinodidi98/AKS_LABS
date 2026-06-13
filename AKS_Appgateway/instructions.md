# Intro and Demo: App Gateway with Ingress Controller for AKS

## Overview

You can integrate Azure Application Gateway (AAG) to expose applications running on AKS.

There are two common patterns.

## Option 1: AGIC (Application Gateway Ingress Controller)

- AGIC runs as a pod inside the AKS cluster.
- The AGIC pod watches and monitors Kubernetes resources such as Ingress.
- When Kubernetes configuration changes, AGIC updates the Azure Application Gateway configuration.
- Application Gateway then routes traffic directly to pods.

![Azure App Gateway](/AKS_AppGateway/images/AzureAppGateway.png)

### Pros

- Good performance.
- Reduced operational effort in some scenarios.

### Cons

- Application Gateway must be updated whenever service routing changes.
- Updates can be heavy operations and can take time.
- Short periods of disruption are possible during updates.
- Because AGIC owns the config, manual changes on Application Gateway are typically overwritten.

## Option 2: Replace AGIC with a Real NGINX Ingress Controller

- Application Gateway forwards user traffic to an ingress controller.
- Traffic path:
  - Client -> Public IP -> VNET[Subnet[App Gateway] -> Subnet[Ingress Internal LB] -> Subnet[AKS]]
- Infrastructure team manages:
  - Public IP
  - Application Gateway
  - TLS certificates
  - DNS records
  - WAF
- Application team manages:
  - Ingress
  - Application routing

### Pros

- Clear ownership boundaries between infrastructure and application teams.
- Easier to share Application Gateway across multiple AKS clusters.

## Demo

### What the Terraform deployment creates

- AKS cluster
- Web App Routing enabled
  - This enables creation of a Microsoft-managed NGINX ingress controller.
  - If configured, it can create an internal load balancer:
    - `default_nginx_controller = "Internal"`
- Azure Application Gateway
  - Public IP
  - V2 SKU
  - Backend routed to a static address
- VNet with dedicated subnets per resource
- Extra subnet for the ingress internal load balancer
- VM for troubleshooting

### Terraform workflow

Run these commands in order:

```bash
terraform init
terraform fmt
terraform validate
terraform apply -auto-approve
```

### Deploy the application

```bash
kubectl apply -f C:\AKS_LABS\AKS_AppGateway\deploy.yaml
```

This deploys a sample image, creates a service, and creates ingress resources.

Deployment exposes enviroment variables from pod where its installed

Private service that will expose the application

Ingress resource that points to the service

using nginx ingress class name that comes from nginx ingress controller. This is the API used by the app routing add-on that is available withing the aks cluster.

Can check in the AKS cluster pods in the app routing system namespace. This containes pods that serve nginx ingress controller 

```bash
kubectl get nodes
kubectl get pods,svc -n app-routing-system
```

### Validate Kubernetes resources

```bash
kubectl get nodes
kubectl get ingressclass
```

- `kubectl get ingressclass` should show the default class created by App Routing.
- This exposes the ingress controller on a public IP adress
- You can delete that default ingress class and create the one in your YAML if you want an internal load balancer.
- The internal load balancer is created withing this subnet `snet-aks-lb` with the static IP adress for the subnet `10.10.1.10`

Also check:

- Pods and services are created successfully.
- Ingress exists and shows the expected private IP address of `10.10.1.10`.

### Validate in Azure

- Check the AKS node resource group:
  - Kubernetes internal load balancer. This is the internal load balancer that will be used by nginx ingress
  - Then go to frontend IP configuration, should show the expected private IP address.
- This is the Private IP that the Application Gateway should route traffic to.
- Then go to Backend Pods.
- Should see that the internal load balancer then routes traffic to AKS nodes.
  - showing the path of from NGINX interal LB to AKS
- The Nginx ingress is exposed through the Private IP address and it gets traffic from the Application Gateway
- Check the Application Gateway resource group (same one as AKS):
  - In Backend pools: Should have 1 Backend pool that should route traffic to the expected private IP address.
    - We specified the target type is IP address or FQDN and then we send traffic to that target
- Application Gateway is also exposed through frontend IP configuration . This should expose the public IP address.
- Copy the public IP and test access from the internet.
- should show application that is served from application gateeway that routed the traffic to NGINX controller and then pods