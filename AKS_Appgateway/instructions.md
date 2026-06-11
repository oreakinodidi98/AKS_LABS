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
kubectl apply -f C:\AKS_LABS\AKS_AppGateway\modules\deploy.yaml
```

This deploys a sample image, creates a service, and creates ingress resources.

### Validate Kubernetes resources

```bash
kubectl get nodes
kubectl get ingressclass
```

- `kubectl get ingressclass` should show the default class created by App Routing.
- You can delete that class and create the one in your YAML if you want an internal load balancer.

Also check:

- Pods and services are created successfully.
- Ingress exists and shows the expected private IP address.

### Validate in Azure

- Check the AKS node resource group:
  - Kubernetes internal load balancer frontend IP configuration should show the expected private IP address.
- This is the IP Application Gateway should route traffic to.
- The internal load balancer then routes traffic to AKS nodes.
- Check the Application Gateway resource group:
  - Backend pool should route traffic to the expected private IP address.
- Application Gateway frontend IP configuration should expose the public IP address.
- Copy the public IP and test access from the internet.