---
title: Caldova Clinical Application
description: Run the Caldova clinical material inventory application locally with Python and PostgreSQL
ms.topic: how-to
---

## Overview

Caldova is a local clinical material inventory application. A Streamlit frontend calls
a FastAPI service, and the service reads normalized inventory data from PostgreSQL.
The API reports database failures directly instead of returning synthetic records.

## Application structure

| Component       | Path                                      | Local runtime                    |
|-----------------|-------------------------------------------|----------------------------------|
| Web entry point | `CaldovaClinicalWeb/app.py`               | Streamlit on port 8501           |
| Web home page   | `CaldovaClinicalWeb/caldova_home.py`      | Streamlit page implementation    |
| Clinical API    | `CaldovaClinicalApi/main.py`              | FastAPI and Uvicorn on port 8000 |
| Database        | `CaldovaClinicalApi/db/init.sql`          | PostgreSQL on port 5432          |

## Prerequisites

Install these local tools before you continue:

* Python 3.11 or later
* PostgreSQL 15 or later
* PowerShell

Open PowerShell, move to the application directory, and locate the PostgreSQL tools:

```powershell
cd C:\AKS_LABS\AKS_AppMod\Scenario1App
$pgBin = (Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin' -Directory |
	Sort-Object FullName -Descending |
	Select-Object -First 1 -ExpandProperty FullName)

if (-not $pgBin) {
	throw 'PostgreSQL was not found. Install PostgreSQL 15 or later before continuing.'
}

& "$pgBin\psql.exe" --version
& "$pgBin\pg_isready.exe" --host 127.0.0.1 --port 5432
```

The readiness command must report `accepting connections`.

## Create the Python environment

Run these commands from the `Scenario1App` directory. Both applications use one local
virtual environment so their dependencies remain isolated from your system Python.

```powershell
python -m venv CaldovaClinicalApi\.venv
$venvPython = Resolve-Path CaldovaClinicalApi\.venv\Scripts\python.exe
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip config --site set global.index-url https://pypi.org/simple
& $venvPython -m pip install --requirement CaldovaClinicalApi\requirements.txt
& $venvPython -m pip install --requirement CaldovaClinicalWeb\requirements.txt
```

The venv-scoped index setting overrides an outdated machine-wide pip index without
changing other projects. If pip reports a TLS error, run these checks:

```powershell
& $venvPython -m pip config debug
Invoke-WebRequest https://pypi.org/simple/ -Method Head
Invoke-WebRequest https://files.pythonhosted.org/ -Method Head
```

Both requests must succeed. A failure for `files.pythonhosted.org` indicates a local
network, proxy, firewall, or HTTPS inspection issue. Use an approved network or ask
your administrator for the required trusted root certificate and proxy settings. Do
not bypass certificate validation with `--trusted-host`.

## Initialize PostgreSQL

Create the `drugs` database and apply the idempotent schema. The PostgreSQL commands
prompt for the `postgres` account password when required.

```powershell
$databaseExists = & "$pgBin\psql.exe" `
	--host 127.0.0.1 `
	--port 5432 `
	--username postgres `
	--dbname postgres `
	--tuples-only `
	--no-align `
	--command "SELECT 1 FROM pg_database WHERE datname = 'drugs';"

if ($databaseExists.Trim() -ne '1') {
	& "$pgBin\createdb.exe" `
		--host 127.0.0.1 `
		--port 5432 `
		--username postgres `
		drugs
}

& "$pgBin\psql.exe" `
	--host 127.0.0.1 `
	--port 5432 `
	--username postgres `
	--dbname drugs `
	--file CaldovaClinicalApi\db\init.sql
```

Running the SQL file more than once is safe. Existing seed records are preserved.

## Data model

The `pharmacy` schema separates catalog, inventory, location, and study data.

| Table             | Purpose                                      |
|-------------------|----------------------------------------------|
| `categories`      | Clinical material classifications            |
| `materials`       | Material catalog and dosage information      |
| `locations`       | Storage facilities and environmental details |
| `inventory_lots`  | Lot quantities, status, and expiry dates     |
| `studies`         | Clinical study records                       |
| `study_materials` | Material quantities assigned to each study   |

Foreign keys connect materials to categories, inventory lots to materials and
locations, and studies to materials through `study_materials`.

## Start the API

Set the connection string for your local PostgreSQL account, then start FastAPI from
the `CaldovaClinicalApi` directory:

```powershell
cd CaldovaClinicalApi
$env:DATABASE_URL = 'postgresql+asyncpg://postgres:<local-password>@127.0.0.1:5432/drugs'
.venv\Scripts\python.exe -m uvicorn main:app --reload
```

Keep the password in an environment variable or local secret store. Do not commit it
to the repository.

Check the API after it starts:

* Health endpoint: <http://127.0.0.1:8000/health>
* Material inventory: <http://127.0.0.1:8000/materials>
* Interactive API reference: <http://127.0.0.1:8000/docs>

## Start the frontend

Open a second PowerShell terminal and run Streamlit from the `Scenario1App` directory:

```powershell
$env:CALDOVA_API_URL = 'http://127.0.0.1:8000'
CaldovaClinicalApi\.venv\Scripts\python.exe -m streamlit run CaldovaClinicalWeb\app.py
```

Open <http://localhost:8501>. The catalog supports material search and inventory
status filtering.

## Validate the application

Compile both Python applications without starting their services:

```powershell
CaldovaClinicalApi\.venv\Scripts\python.exe -m py_compile CaldovaClinicalApi\main.py
CaldovaClinicalApi\.venv\Scripts\python.exe -m py_compile CaldovaClinicalWeb\app.py CaldovaClinicalWeb\caldova_home.py
```

The API returns HTTP 503 when PostgreSQL is unavailable. Confirm the database service,
`DATABASE_URL`, and initialized `pharmacy` schema if either API endpoint reports that
status.
