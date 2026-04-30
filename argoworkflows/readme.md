# Argo Workflows

Open-source workflow orchestrator built on Kubernetes.

## Table of Contents

- [Argo Workflows](#argo-workflows)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [UI Dashboard](#ui-dashboard)
  - [CLI Installation](#cli-installation)
    - [Linux](#linux)
    - [Windows (PowerShell)](#windows-powershell)
  - [Deploying Workflows](#deploying-workflows)
  - [Inspecting Workflows](#inspecting-workflows)
  - [Appendix](#appendix)
    - [Argo CLI Usage](#argo-cli-usage)
    - [DAG Workflow Execution Order](#dag-workflow-execution-order)
  - [CI/CD](#cicd)
    - [Deploy the CI/CD Workflow](#deploy-the-cicd-workflow)
    - [Inspect the CI/CD Workflow](#inspect-the-cicd-workflow)
    - [Benefits of Argo Workflows for CI/CD](#benefits-of-argo-workflows-for-cicd)

## Installation

Create a dedicated namespace and install Argo Workflows:

```bash
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.7.3/install.yaml
```

## UI Dashboard

Patch the Argo Server to disable authentication for local access:

```bash
kubectl patch deployment argo-server -n argo --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args","value":["server","--auth-mode=server"]}]'
```

Port-forward to access the UI:

```bash
kubectl -n argo port-forward deployment/argo-server 2746:2746 --address 0.0.0.0
```

## CLI Installation

### Linux

```bash
wget https://github.com/argoproj/argo-workflows/releases/download/v3.7.3/argo-linux-amd64.gz -O argo.gz
gunzip argo.gz
chmod +x argo
sudo mv argo /usr/local/bin/
argo version
```

### Windows (PowerShell)

```powershell
# Download the Windows binary
Invoke-WebRequest -Uri "https://github.com/argoproj/argo-workflows/releases/download/v3.7.3/argo-windows-amd64.exe.gz" -OutFile "argo.exe.gz"

# Decompress (avoid $input — it is a reserved PowerShell variable)
$inStream = [System.IO.File]::OpenRead("$PWD\argo.exe.gz")
$outStream = [System.IO.File]::Create("$PWD\argo.exe")
$gzip = New-Object System.IO.Compression.GZipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
$gzip.CopyTo($outStream)
$gzip.Close(); $outStream.Close(); $inStream.Close()

# Verify
.\argo.exe version
```

## Deploying Workflows

1. Grant admin permissions to the Argo service account:

```bash
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=argo:default -n argo
```

2. Create a workflow template:

```bash
kubectl apply -f argoworkflows/dag-workflow-template.yaml
```

3. Create and submit a workflow:

```bash
kubectl create -f argoworkflows/dag-workflow.yaml
```

## Inspecting Workflows

```bash
kubectl -n argo get WorkflowTemplate.argoproj.io
kubectl -n argo get Workflow
```

## Appendix

- **Argo Workflows Docs**: <https://argo-workflows.readthedocs.io/>
- **GitHub Releases**: <https://github.com/argoproj/argo-workflows/releases>
- **Version used**: v3.7.3

### Argo CLI Usage

You can also inspect workflows via the Argo CLI:

```bash
argo -n argo list
argo -n argo get dag-diamond-4bgdn
argo -n argo logs dag-diamond-4bgdn
```

### DAG Workflow Execution Order

As we can see, in this workflow, step A runs first since it has no dependencies. After A has finished, steps B and C run simultaneously. When B and C are completed, step D starts. You can also view the completed steps in the Argo UI.

## CI/CD

- **Build**: The build step builds the image with the latest changes, using a Python 3 image for this scenario.
- **Tests**: The test step mounts a volume with test files and runs unit tests with the Python unittest library.
- **Deployment**: The deploy step runs the Python container and prints deploy. Normally, this step would involve pushing the tested code to a container registry (like AWS ECR or Harbor) and then deploying it to the production environment.

### Deploy the CI/CD Workflow

```bash
kubectl -n argo apply -f argoworkflows/workflow-ci.yaml
```

### Inspect the CI/CD Workflow

```bash
argo -n argo list
argo -n argo logs python-app
argo -n argo get python-app
kubectl get pods -n argo
```

### Benefits of Argo Workflows for CI/CD

- **Automation and efficiency**: Argo Workflows automates the CI/CD pipeline, reducing manual intervention and enhancing efficiency.
- **Consistency and reproducibility**: CI/CD processes are defined declaratively, ensuring consistency across multiple runs and environments.
- **Scalability**: Argo Workflows provides scalability, allowing CI/CD processes to scale with the growing needs of the application.
- **Visibility and monitoring**: The UI and CLI provide visibility into workflow execution, allowing teams to monitor progress and troubleshoot issues.
- **Flexibility and customization**: Argo Workflows offers flexibility in defining custom workflows, allowing teams to tailor CI/CD pipelines to their specific requirements.
