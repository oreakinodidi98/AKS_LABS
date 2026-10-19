# Containerized Azure DevOps Agents on AKS with KEDA

## Why 

Why would you need to deploy ADO agents in AKS
Modern CI/CD workloads are dynamic.
During peak deployment hours, build queues increase rapidly, while during idle periods, infrastructure often remains underutilized.
Managing self-hosted Azure DevOps agents manually becomes inefficient, especially when scalability, security, and cost optimization are important.
purpose of this is to create an architecture where Azure DevOps agents automatically scale based on pipeline queue length
Traditional self-hosted agents often face several issues:

Idle VM costs.

Manual scaling.

Secret management complexity.

Long-running agents with stale state.

Security risks from persistent agents.

### Architecture Overview
The solution works as follows:

Azure DevOps pipeline jobs enter an agent pool queue.

KEDA monitors the queue length.

When jobs are pending, KEDA creates Kubernetes jobs dynamically.

AKS pulls the custom agent image from ACR.

The agent registers itself with Azure DevOps.

Secrets are securely fetched from Azure Key Vault through ESO.

After job completion, the agent pod terminates automatically.

This creates a fully ephemeral agent architecture.


Feature	Benefit
Ephemeral agents	Clean execution environment
KEDA autoscaling	Scale only when needed
Key Vault integration	Centralized secret security
Containerized agents	Easy customization
AKS orchestration	Enterprise-grade scalability
ESO synchronization	Native Kubernetes secret consumption