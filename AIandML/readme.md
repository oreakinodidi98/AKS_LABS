# AI and ML workloads in Azure Kubernetes Service

## The Big Picture

- Artificial Intelligence (AI) is changing how we solve problems and help customers. New Generative AI (tools that create things like text, art, or music) makes apps feel much more personal.

## The Challenge

As AI gets smarter, it also gets harder and more expensive to manage. Creating these models is a massive job that requires:

- Serious Power: You need to balance a lot of computer resources to train and run the AI.
- Teamwork: The AI needs to work smoothly with other software and data tools.
- Efficiency: Building and monitoring AI is complicated. If you don't have the right setup, things get slow and messy.

## The Solution

To handle all this complexity without wasting time or money, you need a solid platform like AKS (Azure Kubernetes Service). It acts as the "brain" for your infrastructure, making sure your AI runs at peak performance while cutting out the technical headaches.

## Why Use AKS for AI and ML?

AKS  is the perfect place to run AI apps because it keeps everything organized, reliable, and easy to grow as your needs change.

By using AKS, you get several major benefits:

- High Performance: It provides the heavy duty computer power needed to run complex AI without slowing down.
- Cost & Security: It helps you save money by using resources efficiently while keeping your data locked down and safe
- Less Busywork: AKS handles the "under the hood" technical chores. This means your team spends less time fixing servers and more time building new, innovative features.
- Flexibility: It works perfectly with the popular coding tools and workflows your team likely already uses.

**The Bottom Line:** AKS takes the heavy lifting out of managing AI, so you can launch your projects faster and keep them running smoothly

## RAY Cluster

Ray is an open-source framework for scaling AI and Python applications, providing distributed computing capabilities that are essential for modern machine learning workloads.

Ray allows you to scale your AI workloads from a single machine to a cluster of machines with minimal code changes. It provides several key libraries:

- Ray Core: Distributed computing primitives
- Ray Train: Distributed machine learning training
- Ray Serve: Scalable model serving
- Ray Tune: Hyperparameter tuning at scale
- Ray Data: Distributed data processing

### what is RAY

Ray is a free, open-source tool (started at UC Berkeley) that helps you take a Python program and run it across many computers at once.

#### Why do people use it?

Running big AI tasks on just one computer is often too slow. Ray makes it easy to:

- Scale Up: Grow your project from one laptop to a massive network of servers without a headache.
- Speed Up: It has built-in libraries that make common AI jobs—like training models or fine-tuning settings—happen much faster.
- Do Everything: It handles the entire AI lifecycle, from teaching the model new skills to putting it to work in a real-world app.
- **KubeRay** is an open-source Kubernetes operator for deploying and managing Ray clusters on Kubernetes.
  - KubeRay automates the deployment, scaling, and monitoring of Ray clusters.
  - It provides a declarative way to define Ray clusters using Kubernetes custom resources, making it easy to manage Ray clusters alongside other Kubernetes resources.

### Ray deployment process

1. Set Up AKS infrastructure
2. Install the Helm Ray repository and deploy KubeRay to the AKS cluster using Helm.
3. Download and execute a Ray Job YAML manifest from the Ray GitHub samples repo to perform an image classification with a MNIST dataset using Convolutional Neural Networks (CNNs).
4. Output the logs from the Ray Job to gain insight into the machine learning process performed by Ray.