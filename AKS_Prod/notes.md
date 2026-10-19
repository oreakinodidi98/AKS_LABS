# AKS production architecture guidance

A production AKS setup for high availability + global presence is usually multiple regional AKS clusters, not one giant cluster. Each region is independently survivable, and Azure Front Door routes users to the nearest healthy region.

flowchart TB
    Users[Global users] --> DNS[Azure DNS]
    DNS --> AFD[Azure Front Door Premium + WAF]

    AFD --> R1Ingress[Region 1 HTTPS origin]
    AFD --> R2Ingress[Region 2 HTTPS origin]

    subgraph R1[Azure Region 1]
        R1Ingress --> AppGw1[Application Gateway for Containers / Ingress]
        AppGw1 --> AKS1[AKS cluster - zone redundant]
        AKS1 --> Sys1[System node pool]
        AKS1 --> User1[User node pools across AZ 1/2/3]
        AKS1 --> KV1[Key Vault via Workload Identity]
        AKS1 --> PE1[Private Endpoints]
        AKS1 --> Mon1[Azure Monitor / Prometheus / Grafana]
    end

    subgraph R2[Azure Region 2]
        R2Ingress --> AppGw2[Application Gateway for Containers / Ingress]
        AppGw2 --> AKS2[AKS cluster - zone redundant]
        AKS2 --> Sys2[System node pool]
        AKS2 --> User2[User node pools across AZ 1/2/3]
        AKS2 --> KV2[Key Vault via Workload Identity]
        AKS2 --> PE2[Private Endpoints]
        AKS2 --> Mon2[Azure Monitor / Prometheus / Grafana]
    end

    AKS1 --> Data[(Geo-replicated data layer)]
    AKS2 --> Data

    Data --> Cosmos[Cosmos DB / Azure SQL / PostgreSQL HA]
    Data --> Redis[Azure Cache for Redis Enterprise]
    Data --> Storage[Geo-redundant Storage]

    ACR[Geo-replicated Azure Container Registry] --> AKS1
    ACR --> AKS2

    CICD[GitHub Actions / Azure DevOps + GitOps] --> ACR
    CICD --> AKS1
    CICD --> AKS2

    Hub[Hub VNet: Firewall, Bastion, Private DNS, VPN/ExpressRoute] --> R1
    Hub --> R2

| Layer | Azure services |
| --- | --- |
| Global entry | Azure Front Door Premium, WAF, Azure DNS |
| Regional ingress | Application Gateway for Containers, NGINX Ingress, Gateway API, or Istio |
| Compute | AKS Standard/Premium, multi-zone node pools, cluster autoscaler / node auto-provisioning |
| Networking | VNets, subnets, Azure CNI Overlay or Cilium, Private Link, Private DNS, NAT Gateway / Azure Firewall |
| Identity/secrets | Microsoft Entra ID, AKS Workload Identity, Azure Key Vault, managed identities |
| Images | Azure Container Registry with geo-replication |
| Data | Cosmos DB multi-region, Azure SQL failover groups, PostgreSQL Flexible Server HA/read replicas, Redis Enterprise active geo-replication, GRS/ZRS Storage |
| Observability | Azure Monitor, Container Insights, Managed Prometheus, Managed Grafana, Log Analytics |
| Security/governance | Defender for Containers, Azure Policy, WAF, network policies, image signing/scanning |
| Delivery | GitHub Actions/Azure DevOps, Flux/Argo CD, AKS Fleet Manager for staged upgrades |