---
name: azure-tf-deployment-preflight
description: 'Performs comprehensive preflight validation of Terraform deployments to Azure, including template syntax validation, what-if analysis, and permission checks. Use this skill before any deployment to Azure to preview changes, identify potential issues, and ensure the deployment will succeed. Activate when users mention deploying to Azure, validating Terraform files, checking deployment permissions, previewing infrastructure changes, running what-if, or preparing for terraform apply.'
---

# Azure Terraform Deployment Preflight Validation

This skill validates Terraform deployments before execution, supporting Terraform plan, Azure CLI (`az`) and Azure Developer CLI (`azd`) workflows.

## When to Use This Skill

- Before deploying infrastructure to Azure
- When preparing or reviewing Terraform files
- To preview what changes a deployment will make using Terraform plan
- To verify permissions are sufficient for deployment
- Before running `Terraform apply`, `Terraform init`, or `Terraform plan` commands

## Validation Process

Follow these steps in order. Continue to the next step even if a previous step fails—capture all issues in the final report.

### Step 1: Detect Project Type

Determine the deployment workflow by checking for project indicators:

1. **Check for Terraform project**: Look for `<filename>.tf` in the project root
   - For standalone: Use the file specified by the user or search common locations (`terraform/`, `modules/`, project root)

2. **Auto-detect parameter files**: For each Terraform file, look for matching parameter files:
   - `<filename>.tf` (Terraform parameters - preferred)
   - `variables.tf` (Declares input variables (types, descriptions, defaults)
   - `outputs.tf` (Exposes values after deployment)
   - `backend.tf` (Configures remote state storage (critical for teams and CI/CD).)
   - `providers.tf` (Defines which cloud/provider Terraform talks to and how.)
   - `<filename>.tfvars` (Default variable values loaded automatically- These files assign values to variables declared in variables.tf.)
   - `<filename>.auto.tfvars` (Default variable values loaded automatically - Automatically loaded, great for environment‑specific values.)
   - `.tfvars.json` (Same as .tfvars but JSON format)

### Step 2: Validate Terraform Syntax

Run Terraform command to check template syntax before attempting deployment validation:

```bash
terraform init -backend=false
terraform fmt
terraform validate
```

**What to capture:**
- Syntax errors with line/column numbers
- Validation errors (types, missing vars, invalid references)
- Warning messages
- Build success/failure status

**If Terrafform is not installed:**
- Note the issue in the report
- Continue to Step 3 (Terraform will validate during terraform plan)

### Step 3: Run Preflight Validation

Choose the appropriate validation based on project type detected in Step 1.

#### For azd Projects (azure.yaml exists)

Use `azd provision --preview` to validate the deployment:

```bash
azd provision --preview
```

If an environment is specified or multiple environments exist:
```bash
azd provision --preview --environment <env-name>
```

#### For Standalone Bicep (no azure.yaml)

Determine the deployment scope from the Bicep file's `targetScope` declaration:

| Target Scope | Command |
|--------------|---------|
| `resourceGroup` (default) | `az deployment group what-if` |
| `subscription` | `az deployment sub what-if` |
| `managementGroup` | `az deployment mg what-if` |
| `tenant` | `az deployment tenant what-if` |

**Run with Provider validation level first:**

```bash
# Resource Group scope (most common)
az deployment group what-if \
  --resource-group <rg-name> \
  --template-file <bicep-file> \
  --parameters <param-file> \
  --validation-level Provider

# Subscription scope
az deployment sub what-if \
  --location <location> \
  --template-file <bicep-file> \
  --parameters <param-file> \
  --validation-level Provider

# Management Group scope
az deployment mg what-if \
  --location <location> \
  --management-group-id <mg-id> \
  --template-file <bicep-file> \
  --parameters <param-file> \
  --validation-level Provider

# Tenant scope
az deployment tenant what-if \
  --location <location> \
  --template-file <bicep-file> \
  --parameters <param-file> \
  --validation-level Provider
```

**Fallback Strategy:**

If `--validation-level Provider` fails with permission errors (RBAC), retry with `ProviderNoRbac`:

```bash
az deployment group what-if \
  --resource-group <rg-name> \
  --template-file <bicep-file> \
  --validation-level ProviderNoRbac
```

Note the fallback in the report—the user may lack full deployment permissions.

### Step 4: Capture What-If Results

Parse the what-if output to categorize resource changes:

| Change Type | Symbol | Meaning |
|-------------|--------|---------|
| Create | `+` | New resource will be created |
| Delete | `-` | Resource will be deleted |
| Modify | `~` | Resource properties will change |
| NoChange | `=` | Resource unchanged |
| Ignore | `*` | Resource not analyzed (limits reached) |
| Deploy | `!` | Resource will be deployed (changes unknown) |

For modified resources, capture the specific property changes.

### Step 5: Generate Report

Create a Markdown report file in the **project root** named:
- `preflight-report.md`

Use the template structure from [references/REPORT-TEMPLATE.md](references/REPORT-TEMPLATE.md).

**Report sections:**
1. **Summary** - Overall status, timestamp, files validated, target scope
2. **Tools Executed** - Commands run, versions, validation levels used
3. **Issues** - All errors and warnings with severity and remediation
4. **What-If Results** - Resources to create/modify/delete/unchanged
5. **Recommendations** - Actionable next steps

## Required Information

Before running validation, gather:

| Information | Required For | How to Obtain |
|-------------|--------------|---------------|
| Resource Group | `az deployment group` | Ask user or check existing `.azure/` config |
| Subscription | All deployments | `az account show` or ask user |
| Location | Sub/MG/Tenant scope | Ask user or use default from config |
| Environment | azd projects | `azd env list` or ask user |

If required information is missing, prompt the user before proceeding.

## Error Handling

See [references/ERROR-HANDLING.md](references/ERROR-HANDLING.md) for detailed error handling guidance.

**Key principle:** Continue validation even when errors occur. Capture all issues in the final report.

| Error Type | Action |
|------------|--------|
| Not logged in | Note in report, suggest `az login` or `azd auth login` |
| Permission denied | Fall back to `ProviderNoRbac`, note in report |
| Bicep syntax error | Include all errors, continue to other files |
| Tool not installed | Note in report, skip that validation step |
| Resource group not found | Note in report, suggest creating it |

## Tool Requirements

This skill uses the following tools:

- **Azure CLI** (`az`) - Version 2.76.0+ recommended for `--validation-level`
- **Azure Developer CLI** (`azd`) - For projects with `azure.yaml`
- **Bicep CLI** (`bicep`) - For syntax validation
- **Azure MCP Tools** - For documentation lookups and best practices

Check tool availability before starting:
```bash
az --version
azd version
bicep --version
```

## Example Workflow

1. User: "Validate my Bicep deployment before I run it"
2. Agent detects `azure.yaml` → azd project
3. Agent finds `infra/main.bicep` and `infra/main.bicepparam`
4. Agent runs `bicep build infra/main.bicep --stdout`
5. Agent runs `azd provision --preview`
6. Agent generates `preflight-report.md` in project root
7. Agent summarizes findings to user

## Reference Documentation

- [Validation Commands Reference](references/VALIDATION-COMMANDS.md)
- [Report Template](references/REPORT-TEMPLATE.md)
- [Error Handling Guide](references/ERROR-HANDLING.md)