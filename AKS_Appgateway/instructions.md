# Intro and demo for App Gateway with Ingress Controller for AKS

## Intro

- can integrate Azure Application Gateway (AAG) to expose AKS applications
- 2 options
  - AGIC -> Azure Application Gateway Ingress Controller
    - App Gateway is managed by AGIC (Pod running inside Cluster)
    - Pod watvches and monitores K8 resources like ingress
    - For any changes AGIC will update configuration of Azure App Gateway
    - App gateway then routes traffic directly to pod
    - ![Azure App Gateway](/AKS_AppGateway/images/AzureAppGateway.png)
    - **Good** : performance and reduced the number of Ops
    - **Bad**: Have to update Azure App Gateway whenever we have a change of service, so might be out of service for few minutes. Heavy operation and takes time. Plus owned by cluster so changes are always overidden by AGIC component
  - Replace AGIC with Real NGINX ingress Controller
    - App gateway will forward user traffic to ingress Controller
    - Client -> Public IP -> VNET[Sunet[App Gateway]->Subnet[Ingress. Internal-LB]->Subnet[AKS]]
    - Infra Team manage: Public IP and App Gateway
      - TLS cert
      - DNS record
      - WAF etc
    - App team Manage : Ingress and AKS
      - Ingress
      - Application routing
    - Good: decouple parts that are owned by different teams. Makes it easy for App Gateway to be shared and used by multiple clusters

## Demo