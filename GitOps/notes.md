# Gitops

- Developer centric approact to deploy an application
- Continuous delivery deployment to Kubernetes environment in autonomus way

## What is GitOps

- GitOps is a collection of principles that guide modern software delivery and operations.
- It provides a structured, reliable way to manage infrastructure and applications through version control.
- There are 5 key aspects of GitOps that streamline, standardize, and optimize development and deployment.
  - **Declarative configuration**
    - Defining the desired state of your system rather than how to get there.
    - In practice, developers describe the intended outcome
    - E.G. an application should run three containers. Automated agents then compare the current system state to this desired configuration and make the necessary adjustments, such as adding or removing containers. This approach contrasts with the traditional imperative style, in which specific commands are issued step by step to achieve the desired setup.
  - **Immutable storage**
    - In GitOps, the Git serves are a version-control system and also as an immutable storage for configurations.
    - Once a configuration is committed to Git, it becomes a fixed reference point, providing a reliable record that supports reproducibility and traceability
    - Making Git the single source of truth for your system’s desired state. 
    - Although Git is the most commonly used tool for this purpose, the core principles of GitOps can also be applied with other version control systems.
  - **Automation**
    - Focuses on removing manual steps after changes are committed to version control.
    - Once an update is made, software agents take over, analyzing the difference between the system’s current state and the desired state defined in the repository.
    - They then apply the necessary changes to implement the newly declared configuration, bringing the system into alignment.
    - This continuous reconciliation process represents the closed-loop nature of GitOps, ensuring that deployments remain consistent, reliable, and up to date without human intervention.
  - **Closed loop**
    - The continuous feedback process that compares the system’s actual state with its desired state.
    - Automated agents constantly monitor for differences between the two and take corrective action whenever the system drifts from the configuration defined in version control.
    - This ensures the environment is always moving toward the declared state, maintaining consistency, reliability, and predictability in operations.

## ARGO

- Argo is a set of Kubernetes native tools that enhance the workflow management capabilities of Kubernetes. 
- Argo is made up of:
  - **Argo Continuous Delivery** (CD) for state management
  - **Argo Workflows** for running complex jobs
  - **Argo Events** for event-based dependency management
  - **Argo Rollouts** for progressive delivery
- These tools are designed to help you automate and manage tasks in a Kubernetes environment, making it easier to deploy, update, and manage applications.
- Each of these tools can run independently and do not require the others to work, but they are capable of working together.

### Benefits of Argo

- Argo is an open-source toolset that makes GitOps easier to use with Kubernetes.
- It helps teams deploy in a safer and more reliable way, while reducing manual work.
- Tools like Argo CD and Argo Rollouts make advanced release patterns easier, including canary and blue-green deployments.
- Argo automation helps teams ship features faster and roll back quickly when checks show something is wrong.
- Since everything is tracked in Git, you get a clear audit trail of changes. 
- Argo also works well with tools like Prometheus, Helm, NATS, and CloudEvents.

### Argo CD

- Declarative GitOps continuous delivery (CD) tool designed for Kubernetes.
- Automates the process of applying Kubernetes manifests from a Git repository to a cluster and continuously monitors the repository for changes.
- When updates are detected, Argo CD automatically synchronizes the cluster to match the desired configuration defined in Git.
- This makes it an ideal tool for managing both infrastructure and application deployments, ensuring that production environments always reflect the exact state specified in version control.

#### Argo CD extension on AKS

- GitOps is becoming the standard for deploying and operating applications at scale
- Enterprises need a way to implement GitOps while staying compliant with best practices for security and identity management
- Also available on Azure Arc enabled Kubernetes clusters
- Argo CD extension delivers on this need across 3 pillars
  - Trusted Identity and Secure Access
  - Enterprise-Grade Hardening and Security
  - Parity with upstream Argo CD

![ArgoCD Extension](./image/argocd.png)

#### Getting Started

- [link](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-argocd)

### Argo Workflows

- Argo Workflows extends Kubernetes with a Workflow resource that works a lot like a Kubernetes Job, but gives you more flexibility.
- Because of that, it can be used in many areas, especially machine learning and data pipelines.
- Many teams use it to run complex process flows in a cleaner, more organized way.
- In Argo Workflows, each step runs as its own pod, which makes workflows easier to scale and manage.
- It supports parallel execution, so it works well for data processing and automation. A common example is fan-out/fan-in, where work is split into many tasks, run at the same time, then combined at the end.

### Argo Events

- Event driven workflow automation framework for Kubernetes that helps you trigger Kubernetes objects, Argo Workflows, serverless workloads, and other processes in response to events from various sources such as webhooks, S3, schedules, messaging queues, GCP PubSub, and more.
- It supports events from various sources and allows you to customize business level constraint logic for workflow automation.
- Argo Events has two main components: Triggers and Event Sources.
- Triggers are responsible for executing actions when an event occurs.
- Event Sources are responsible for generating events.
- Use cases of Argo Events include automating research workflows, designing a complete CI/CD pipeline, and automating everything by combining Argo Events, Workflows & Pipelines, CD, and Rollouts.

### Argo Rollouts

- Argo Rollouts is a Kubernetes tool for safer app releases.
- It was created because basic Kubernetes deployments are limited.
- It supports blue-green and canary deployments, can control traffic with service meshes and ingress, and can automatically promote or roll back releases based on checks. This helps teams ship new features to production more safely and with less manual work.

## Tools 
- Flux CD
- Argo CD
- Jenkins
