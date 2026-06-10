# Creating Scalable and Resilient Systems

## The Platform Engineering Journey

Platform engineering evolves as DevOps practices mature over time. It is built on top of DevOps and focuses on improving how development teams build, ship, and operate software.

### Key Challenges

- Be agile
- Get teams onboarded and started quickly
- Accelerate time to market
- Support different technology stacks
- Reduce tribal knowledge risk when people leave or move teams
- Maintain consistent standards across teams
- Avoid suboptimal designs that increase:
  - Cost
  - Security and risk exposure
  - Time to business value

### Working Definition

Platform engineering is a practice built from DevOps principles that improves each development team's security, compliance, cost efficiency, and time to business value through improved developer experience and self-service in a governed framework.

It is both:

- A product-based mindset shift
- A set of tools and systems to support that mindset

### Typical Steps (often happening in parallel)

1. **Establish a Platform Engineering Product Team**
   - A dedicated product team responsible for creating a self-service developer portal
   - Define platform adoption strategies
2. **Inventory and Centralization**
   - Inventory existing tools, systems, APIs, and application platforms
   - Evaluate usage to decide where to invest or deprecate, then centralize and reduce redundancy
3. **Automate High-Toil Areas**
   - Automate areas of high developer effort (human-in-the-loop processes)
4. **Build Paved Paths**
   - Create templates that give developers successful, repeatable paths based on organizational best practices
5. **Deploy Environment as a Service**
   - Enforce guardrails and separation of concerns for security
   - Provision infrastructure on behalf of teams to prevent over-privileged access
6. **Optimize Self-Service Developer Experience**
   - Deliver self-service with guardrails that are easy to consume, secure, and compliant by design
   - Offer the platform as a product

## Microsoft Perspective

Provide a standardized, secure, and scalable foundation for development teams across Microsoft.

- Build from both retail and open-source products
- Turn learnings into product improvements

## Focus Areas

### Core Loop

- Speed and innovation
- Trust and quality
- Collaboration and scale
- Talent and developer happiness

## Metrics and KPIs

- Identify the biggest pain points
- Measure and establish a baseline
- Start small and iterate by leveraging assets already in your environment
- Recognize that many customers are currently stitching solutions together

### Example KPI Categories

- **Customer usage**
  - How much value are users getting?
  - Acquisition, retention, engagement, satisfaction, feature usage
- **Pipeline throughput**
  - How efficient is the DevOps process?
  - Time to build, test, deploy, and improve
  - Failed and flaky automation rates
- **Live-site health**
  - How quickly can issues be detected and fixed?
  - Time to detect, communicate, and mitigate
  - Customer impact and support metrics
  - Incident prevention items
  - Aging live-site problems
  - SLA by customer
- **Employee health**
  - How are employees doing?
  - Burnout, vacation time, and employee concern surveys

Meet developers where they are and provide the right information so the platform can drive automation effectively.

## Common Goals for Platform Engineering Practices

- Enable self-service
- Provide guardrails in a secure and governed way
- Facilitate rapid development and onboarding
- Treat infrastructure as self-service
- Manage and control cost

## Shift to a Product Mentality

## Abstracting Complexity

- Enabling a development team to self-service infrastructure and tools is a good starting point
- Providing a fully preconfigured app hosting environment that enables immediate development is even better
- This allows teams to start producing results faster, improving time to value and reducing cognitive overload
- The demos focus on how a development lead can obtain an application hosting environment for a stateful service app
  - The environment includes Azure resources, cloud-native applications, and an AKS cluster where workloads can authenticate with a secret store and retrieve the connection string required to run the application
  - This can all be done with minimal required knowledge from the developer

### Demo 1: Development Lead Self-Service Environment (Terraform + GitHub Actions)

1. A development lead opens a self-service catalog and selects an application template (deploys resources and uses an existing cluster)
2. A pull request is raised in the project repository, which starts automation
3. An AKS cluster already exists (preconfigured and managed by the platform team)
4. Azure Policy handles observability, security, and compliance
5. GitHub Actions and Terraform deploy resources to Azure (database, secret store, identity, ACR)
6. The platform engineering team has already configured the cluster with the Key Vault provider CSI driver
7. Terraform continues deployment by creating a user-assigned identity and federating it for workload identity and Secret Store CSI driver secret injection into pods
8. The pipeline emits parameters needed to deploy the application

### Demo 2: Cloud-Native Approach

- This is the cloud-native approach to Demo 1
- Why this approach:
  - Demo 1 works well, but this model improves self-service using Azure-oriented abstractions, reusable modules, policy alignment, and Kubernetes-native state tracking
  - Terraform primarily detects and reacts to state changes from its own state model, while this approach keeps reconciliation inside the Kubernetes control plane
- Uses open-source tools: Crossplane and Argo
- **BACK stack**: Backstage, Argo, Crossplane, Kratix
- Key difference: a management cluster hosts Argo and Crossplane

#### Crossplane

- A cloud-native infrastructure-as-code tool
- Represents infrastructure resources as Kubernetes resources
- Uses the Kubernetes control plane as the infrastructure lifecycle management plane for cloud infrastructure
- Enables RBAC on individual infrastructure resources
- Must be deployed on the management cluster

#### Argo CD

- A GitOps continuous delivery tool
- Reconciles to a single source of truth

#### Process

1. Argo notices a PR or repo change (in project Repo) and picks up the new desired configuration and starts creating all those resources
2. Crossplane reconciles and provisions/updates cloud resources based on that desired state, while Argo continues to enforce Git as source of truth
3. Crossplane creates another  Argo application Configuration and deploys it to the shared AKS app cluster (downstream cluster)
4. This App configuration connects to the develper repository , downloads and installs the configuration

## Enabling Self-Service Through Automation

Self-service through automation is a key aspect of an engineering platform.

### Platform Layers

- **Top layer**
  - Developer identity
  - Orchestration and automation
  - Platform and API catalog
  - Team insights
- **Foundation**
  - Application templates (automation templates)
  - Application platform (opinionated stacks), meaning the platform you actually run on (for example, Kubernetes)
  - Engineering systems that reduce friction (for example, GitHub Actions)

### Azure Deployment Environments

- Self-service infrastructure as code
- Typical use case: a Kubernetes environment where developers are given isolated namespaces

### Example Flow

- Background:
  - The platform engineering team has already created the paved path (shared cluster)
- Developer journey:
  - A developer provisions the infrastructure they need
  - The developer then uses AZD (Azure Developer CLI) to deploy code
  - `azd env list` can be used to view available environments
  - `azd deploy` deploys resources to the AKS cluster in an isolated namespace that reflects resources in the Azure deployment environment

## Copilot Extensibility and Platform Engineering

- How we can take Copilot and apply it to platform engineering
- Use AI to create an Azure deployment environment with the required resources
- Deployment environments can work across tenants
- Enables creation of isolated environments
- Take the tools already used in your environment, make them easy to integrate and extend, and surface them through the tools developers already use, including Copilot
- Simplify what developers need to do through platform engineering and increase developer joy and satisfaction
