---
title: AKS Application Modernization
description: Run Caldova locally, then modernize it into a secure, production-ready AKS application
ms.topic: tutorial
---

## Overview

In this scenario, I take the Caldova clinical inventory application from source code
to a secure, production-ready deployment on Azure Kubernetes Service (AKS). I start
by running the application locally so I can understand how the frontend, API, and
database work together before I generate any container or Kubernetes artifacts.

Caldova uses Python across the application stack:

| Component | Technology              | Local address                 |
|-----------|-------------------------|-------------------------------|
| Frontend  | Streamlit               | <http://localhost:8501>       |
| API       | FastAPI and Uvicorn     | <http://127.0.0.1:8000>       |
| Database  | PostgreSQL              | `127.0.0.1:5432`              |

The application source is in the [Scenario1App](./Scenario1App/) directory. For a
closer look at the data model and individual components, see the
[Caldova application guide](./Scenario1App/README.md).

## What I do in this scenario

I use this scenario to move through the full AKS application lifecycle:

1. Review the frontend, backend, and PostgreSQL schema to understand the application.
2. Run and validate the complete application locally.
3. Generate the container build and Kubernetes deployment artifacts.
4. Use Azure Container Registry (ACR) to build and store the application images.
5. Configure Microsoft Entra Workload ID for access to PostgreSQL and Azure Key Vault.
6. Connect the application service to the existing Gateway API resource with an
   `HTTPRoute`, TLS, and a custom domain name.
7. Review the generated files and prepare them for commit.
8. Create a GitHub Actions workflow to automate build, test, and deployment.
9. Use AKS Desktop to inspect the workloads and HTTP routes.

## Prerequisites

Before I run the application locally, I install:

* Python 3.11 or later
* PostgreSQL 15 or later
* PowerShell

## Run the application locally

I run the following commands from the `AKS_AppMod` directory.

### Create the Python environment

I use one virtual environment for the API and frontend dependencies. This keeps the
packages isolated from my system Python installation.

```powershell
cd Scenario1App
python -m venv CaldovaClinicalApi\.venv
CaldovaClinicalApi\.venv\Scripts\python.exe -m pip install --requirement CaldovaClinicalApi\requirements.txt
CaldovaClinicalApi\.venv\Scripts\python.exe -m pip install --requirement CaldovaClinicalWeb\requirements.txt
```

### Initialize PostgreSQL

I create the `drugs` database and apply the idempotent schema and seed data. These
commands prompt for the local `postgres` account password when required.

```powershell
createdb --host 127.0.0.1 --port 5432 --username postgres drugs
psql --host 127.0.0.1 --port 5432 --username postgres --dbname drugs --file CaldovaClinicalApi\db\init.sql
```

Running the SQL file again is safe because it preserves existing seed records.

### Start the API

From the `Scenario1App` directory, I set the PostgreSQL connection string and start
the FastAPI service:

```powershell
cd CaldovaClinicalApi
$env:DATABASE_URL = 'postgresql+asyncpg://postgres:<local-password>@127.0.0.1:5432/drugs'
.venv\Scripts\python.exe -m uvicorn main:app --reload
```

> [!IMPORTANT]
> I replace `<local-password>` with my local PostgreSQL password. I keep credentials
> in environment variables or a local secret store and never commit them.

After the API starts, I verify these endpoints:

* Health check: <http://127.0.0.1:8000/health>
* Material inventory: <http://127.0.0.1:8000/materials>
* Interactive API reference: <http://127.0.0.1:8000/docs>

### Start the frontend

I open a second PowerShell terminal, return to the `Scenario1App` directory, and run
the Streamlit frontend:

```powershell
$env:CALDOVA_API_URL = 'http://127.0.0.1:8000'
CaldovaClinicalApi\.venv\Scripts\python.exe -m streamlit run CaldovaClinicalWeb\app.py
```

I then open <http://localhost:8501> and confirm that I can search the material catalog
and filter inventory by status.

## Validate the local application

I can check the Python files without starting either service:

```powershell
CaldovaClinicalApi\.venv\Scripts\python.exe -m py_compile CaldovaClinicalApi\main.py
CaldovaClinicalApi\.venv\Scripts\python.exe -m py_compile CaldovaClinicalWeb\app.py CaldovaClinicalWeb\caldova_home.py
```

The API returns HTTP 503 when PostgreSQL is unavailable. If that happens, I confirm
that PostgreSQL is running, `DATABASE_URL` is correct, and the `pharmacy` schema has
been initialized.

## Modernize the application for AKS

After the local application works, I generate and review the container images,
Kubernetes resources, and CI/CD workflow. ACR builds and stores the images, so I do
not need a local container build environment for the AKS deployment workflow.

The Caldova platform engineering team has already provisioned the Gateway resource.
I only need to create an `HTTPRoute` that connects the application service to that
gateway through the required custom domain.

I can use this prompt to generate the route:

```text
Help me generate an HTTPRoute that connects the Caldova service to the existing
Gateway using a custom domain name.
```

I also configure Microsoft Entra Workload ID so the pods can connect to PostgreSQL
and Azure Key Vault without storing credentials in the deployment manifests.

```text
Configure Workload ID so the Caldova application can connect to PostgreSQL and
Azure Key Vault without storing credentials in the pods.
```

Finally, I inspect the deployment and HTTP routes in AKS Desktop, review the generated
files, and create a pull request. The GitHub Actions workflow then uses ACR to build
and store the application images before deploying them to AKS.
