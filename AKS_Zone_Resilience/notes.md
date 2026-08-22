---
title: AKS Zone Resilience
description: Notes on two-zone AKS resilience, regional capacity constraints, and capacity reservation options
---

## Contents

| Section | What it covers |
| --- | --- |
| [Background](#background) | Customer scenario and reason for the engagement |
| [Customer requirements and constraints](#customer-requirements-and-constraints) | Regional dependencies and capacity limitations |
| [Key takeaways](#key-takeaways) | Main lessons from the discussion |
| [How a two-zone AKS deployment remains resilient](#how-a-two-zone-aks-deployment-remains-resilient) | Capacity impact of a zone failure |
| [Stateless and stateful applications](#stateless-and-stateful-applications) | Simple explanation of the two workload types |
| [Capacity assurance with ODCR](#capacity-assurance-with-odcr) | Guaranteed capacity and commercial considerations |
| [Architecture decision guidance](#architecture-decision-guidance) | Questions to guide the final design |
| [Zone-resilient deployment types](#zone-resilient-deployment-types) | Difference between zonal and zone-redundant resources |

## Background

A customer requested a confidence call about future capacity availability and architectural guidance for a two-zone Azure Kubernetes Service (AKS) deployment. I captured the key points and lessons from the engagement in these notes.

The customer originally required an AKS deployment across three availability zones in the South Central region because of dependencies on existing infrastructure. However, regional capacity constraints and other technical limitations prevented the requested deployment. This led to a broader discussion about two-zone resilience, alternative Azure regions, and the impact of moving the workload to another region.

## Customer requirements and constraints

The engagement highlighted the following requirements and constraints:

* The customer's initial AKS deployment needed to span three availability zones, with a minimum of 16 cores in each zone.
* Existing infrastructure dependencies made South Central the preferred region.
* Current capacity limitations prevented the required three-zone deployment in South Central.
* After the initial deployment, the cluster could scale across only two zones.
    This limitation reflects the capacity currently available in many regions,
    including South Central.
* Moving to another region could provide different capacity options, but the effect on existing infrastructure dependencies would need to be evaluated.

## Key takeaways

The discussion produced several important takeaways:

* Due to global supply constraints, the industry is increasingly adopting two-zone architectures as a standard approach. Azure documentation and services are also being updated to reflect this shift.
* The service-level agreement (SLA) for a two-zone deployment is effectively the same as the SLA for a three-zone deployment within a single region.
* Customers need clear guidance about the negligible SLA difference and the operational benefits of a two-zone deployment.
* The primary architectural tradeoff is the amount of capacity lost during a zone failure, rather than a significant difference in the regional SLA.

## How a two-zone AKS deployment remains resilient

> [!NOTE]
> A two-zone AKS deployment remains resilient to a single-zone outage because
> AKS can distribute node pools across both zones and continue serving
> workloads from the surviving zone.

The capacity impact of a zone failure differs between two-zone and three-zone
designs:

| Design      | Approximate capacity lost during one zone failure | Approximate capacity remaining |
|-------------|---------------------------------------------------|--------------------------------|
| Two zones   | 50%                                               | 50%                            |
| Three zones | 33%                                               | 67%                            |

## Stateless and stateful applications

In simple terms, the difference is whether the application needs to remember information locally between requests:

* A **stateless application** does not depend on information stored inside a
     specific application instance or pod. Each request can be handled
     independently by any available pod. If one pod fails, another pod can take
     over without needing to recover information from the failed pod.
* A **stateful application** needs to preserve information between requests or
     depends on a stable identity, ordered processing, or persistent storage. If
     its pod fails, the replacement might need to reconnect to its storage,
     recover data, or rejoin the other application replicas before it can serve
     traffic safely.

| Characteristic | Stateless application | Stateful application |
| --- | --- | --- |
| Simple analogy | A receptionist who can handle the next request without knowing the previous conversation | A personal account manager who must retain the customer's history |
| Common examples | Web front ends, REST APIs, and request-processing services | Databases, message brokers, and applications that store local session data |
| Where data is kept | In an external service, such as a database, distributed cache, or object store | In persistent storage or replicated state managed by the application |
| If a pod fails | Another pod can usually serve the next request immediately | A replacement might need to restore data, attach storage, or rejoin a replica group |
| Scaling | Usually straightforward because any replica can handle a request | Requires care to preserve data consistency, identity, and replica membership |
| Zone outage concern | Enough healthy pods and compute capacity must remain in the surviving zone | Data replicas, storage availability, quorum, and recovery behavior must also survive |

> **Memory line:** Stateless applications can replace a pod and continue;
> stateful applications must also preserve and recover what the pod knows.

For stateless applications, a two-zone design is a supported resilient architecture when the application can absorb the capacity reduction through one or more of the following measures:

* Autoscaling
* Load shedding
* Deliberate overprovisioning

Stateful workloads need additional consideration. Workloads that require quorum might still need a three-zone design or additional multi-region protections to meet their availability and recovery requirements.

## Capacity assurance with ODCR

On-demand capacity reservation (ODCR) was discussed as an alternative for guaranteeing AKS compute capacity. It is the only guaranteed method of reserving capacity in Azure and is suitable for workloads that run 24 hours a day, seven days a week.

An ODCR can be configured in the Azure portal by creating a capacity reservation group. The following commercial considerations apply:

* ODCR does not increase the per-unit price of the reserved compute capacity.
* Azure charges for the reserved capacity whether or not the workload uses it.
* Future capacity reservation options with minimum usage periods are being piloted.

Before choosing ODCR, it is important to establish the customer's actual capacity requirements. Quota approvals are region-based and must be managed carefully while supply remains constrained.

## Architecture decision guidance

The architecture discussion should consider the following questions:

1. Does the workload require three zones for a technical reason, such as stateful quorum, or is the requirement based on a general resilience goal?
2. Can the application continue operating after losing approximately 50% of its in-region capacity?
3. Can autoscaling, load shedding, or overprovisioning provide enough capacity protection for a two-zone deployment?
4. Would moving to another region introduce unacceptable effects on existing infrastructure dependencies?
5. Does the workload run continuously and justify paying for guaranteed capacity through ODCR?
6. Are the required regional quota and capacity approvals available?

For this customer, the key message was that a two-zone AKS architecture can provide supported single-zone-failure resilience. The final choice should be based on workload behavior, capacity-loss tolerance, stateful quorum needs, regional dependencies, and the cost of guaranteed capacity.

## Zone-resilient deployment types

One useful distinction I learned is that Azure resources can provide zone resilience in two ways: **zonal** or **zone-redundant**. The main difference is who manages the distribution, replication, and failover across availability zones.

### Zonal deployments

A zonal resource is pinned to one specific availability zone. The customer is responsible for designing the application to remain available if that zone fails.

* The customer must distribute application requests across zones and manage data replication between them.
* If one availability zone has an outage, the customer must fail over the application to resources in another zone.
* Zonal resources can be deployed in regions that have only two unconstrained availability zones.
* Infrastructure as a service (IaaS) resources commonly support zonal deployments. A smaller subset of platform as a service (PaaS) resources also supports them.
* Multiple zonal deployments can be placed in different zones and combined to meet higher reliability requirements.

### Zone-redundant deployments

With a zone-redundant resource, Microsoft manages the work required to spread the service across availability zones.

* Microsoft distributes requests and replicates data across zones.
* If one availability zone has an outage, Microsoft manages the failover automatically.
* Most PaaS services are designed to support zone-redundant deployments.
* With a few documented exceptions, zone-redundant services require three availability zones to maintain quorum and data consistency.

> **Memory line:** With zonal resources, the customer designs and manages cross-zone resilience. With zone-redundant resources, Microsoft manages it as part of the service.

##