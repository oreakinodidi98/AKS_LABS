````markdown
# Turn your agents into AKS experts: Agent Skills for AKS



Agent skills for Azure Kubernetes Service (AKS) bring production-grade AKS guidance, troubleshooting checklists, and guardrails directly into any compatible AI agent. The first set of skills are now available through the GitHub Copilot for Azure extension, with support for VS Code, Visual Studio, Copilot CLI, and Claude.

While AI agents already carry a good baseline of Kubernetes and AKS knowledge, that knowledge is only as current as their training data and varies across models. Skills enhance agents with prescriptive, up-to-date guidance on the tools and processes AKS engineers use today to make the right decisions across cluster creation, operations, and issue resolution.

---

## What are agent skills?

Agent skills are an open standard pioneered by Anthropic for enhancing AI agents with domain-specific expertise in a token-efficient way.

- Install a skill once, and any compatible agent (GitHub Copilot, Claude, Gemini, etc.) can use it automatically.
- Skills activate only when relevant:
  - If you're not asking about AKS, they stay inactive.
  - If you ask an AKS-related question, they load automatically with guidance, commands, and context.

---

## Available skills

### 1. AKS Best Practices Skill
Provides guidance on:
- Networking
- Upgrade strategy
- Security
- Reliability
- Scaling

Example prompts:
- "What are the best practice recommendations for a highly reliable and performant AKS cluster?"
- "Help me determine Day-0 decisions for a new AKS cluster."
- "What networking setup is best for my AKS cluster?"

### 2. AKS Troubleshooting Skills
Covers:
- Node health failures
- Networking issues

Includes:
- Exact CLI commands
- Diagnostic workflows used internally by AKS engineers
- Permission-aware execution (only runs what your credentials allow)

---

## Example interaction

**User:**  
"What are the best practices for deploying a secure, reliable, and cost-efficient AKS cluster?"

**Copilot:**  
- Loads AKS-specific guidance  
- Provides production-ready checklist  
- Focuses on Day-0 decisions, autoscaling, and guardrails  

---

## How to get started

### Option 1: GitHub Copilot for Azure plugin

#### Install in VS Code:
1. Open Extensions (`Ctrl+Shift+X`)
2. Search **GitHub Copilot for Azure**
3. Install
4. Open Copilot Chat (`Ctrl+Alt+I`)
5. Run an AKS-related prompt

**Tip:**  
If skills don’t activate:
- Run `GitHub Copilot for Azure: Refresh Skills`
- Or trigger with an AKS-related query

#### Install in Claude or Copilot CLI:
```bash
/plugin marketplace add microsoft/azure-skills
/plugin install azure@azure-skills
/plugin update azure@azure-skills
/skills
````

---

### Option 2: Install skills directly

```bash
npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-kubernetes
npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-diagnostics
```

Or:

* Download from repo
* Place in:

  * `~/.copilot/skills`
  * `~/.claude/skills`

---

## AI-powered AKS capabilities

| Capability          | Role                  | Requires Cluster | Best For                |
| ------------------- | --------------------- | ---------------- | ----------------------- |
| AKS Skills          | Knowledge             | No               | Config, troubleshooting |
| AKS MCP Server      | Tools                 | Yes              | Live diagnostics        |
| Agentic CLI for AKS | End-to-end experience | Yes              | Full operations         |

---

### AKS MCP Server

* Executes actions (skills = guidance, MCP = execution)
* Provides:

  * Secure cluster access
  * API interaction
  * Structured diagnostics

---

### Agentic CLI for AKS

* Purpose-built terminal experience
* Combines:

  * Skills
  * MCP server
  * AI workflows

---

## Creating your own skills

You can extend capabilities with internal skills:

### Good candidates:

* Governance rules (tags, regions, SKUs)
* Security policies (network isolation, identity)
* Platform standards (DNS, ingress, observability)
* Troubleshooting runbooks

---

## Conclusion

AKS skills:

* Bring production-grade knowledge into AI agents
* Use real AKS engineering practices
* Cover best practices and troubleshooting (initial release)

Future expansions will be driven by customer feedback.

---

## Resources

* Azure Kubernetes skill
* Azure diagnostics skill
* Microsoft Skills repository

---

# AKS-MCP Server: Unlock Intelligent Kubernetes Operations

**August 6, 2025 · 9 min read**
**Paul Yu**
*Cloud Native Developer Advocate*

---

## Why deploy MCP servers on AKS?

### Benefits:

* Centralized deployment
* Scalability and reliability
* Secure authentication (Workload Identity)
* Multi-client access
* Governance and auditability

---

## Prerequisites

* Azure subscription
* Azure CLI
* kubectl
* Node.js + npm
* POSIX shell (bash/zsh)

---

## Setup steps

### Login and enable features:

```bash
az login
az extension add --name aks-preview
az feature register --name DisableSSHPreview --namespace Microsoft.ContainerService
```

---

### Create resources:

```bash
export RANDOM_NAME=$(petname)
export LOCATION=westus3
export RESOURCE_GROUP_NAME=rg-$RANDOM_NAME
export AKS_CLUSTER_NAME=aks-$RANDOM_NAME
export MANAGED_IDENTITY_NAME=mi-$RANDOM_NAME
```

---

### Create AKS cluster:

```bash
az aks create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $AKS_CLUSTER_NAME \
  --enable-workload-identity \
  --enable-oidc-issuer \
  --ssh-access disabled \
  --node-count 1
```

---

### Create managed identity:

```bash
az identity create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $MANAGED_IDENTITY_NAME
```

---

### Assign permissions:

```bash
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Contributor" \
  --scope $RESOURCE_GROUP_ID
```

> ⚠️ Use least privilege in production

---

## Deploy Kubernetes resources

### Service Account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aks-mcp
  annotations:
    azure.workload.identity/client-id: $CLIENT_ID
```

---

### ClusterRoleBinding:

```yaml
kind: ClusterRoleBinding
roleRef:
  kind: ClusterRole
  name: cluster-admin
```

---

### MCP Deployment:

```yaml
containers:
- name: aks-mcp
  image: ghcr.io/azure/aks-mcp:v0.0.9
  args:
    - --access-level=readwrite
    - --transport=streamable-http
```

---

## Verify deployment

```bash
kubectl get pods -l app=aks-mcp -w
kubectl logs deploy/aks-mcp
```

---

## Expose service

```yaml
kind: Service
type: ClusterIP
port: 8000
```

---

## Test with MCP Inspector

```bash
kubectl port-forward svc/aks-mcp 8000:8000 &
npx @modelcontextprotocol/inspector
```

* URL: `http://localhost:8000/mcp`
* Tool: `az_aks_operations`

---

## Conclusion

You deployed:

* AKS MCP server
* Workload Identity authentication
* Centralized AI tooling hub

---

## Next steps

* Add monitoring (Azure Monitor)
* Implement network policies
* Configure ingress
* Scale for production

---

## Troubleshooting

If you see:

```
Please run az login
```

Check:

* Federated identity config
* Service account annotations

---

## Cleanup

```bash
pkill -f 'kubectl port-forward'
az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait
```

---

# CLI Agent for AKS

**August 15, 2025 · 9 min read**

AI-powered CLI for:

* Troubleshooting
* Optimization
* Operations

---

## Example commands

```bash
az aks agent "why is my node NotReady?"
az aks agent "why are my pods failing DNS?"
az aks agent "optimize my cluster cost"
```

---

## Key features

* Human-in-the-loop safety
* Transparent diagnostics
* Azure RBAC integration
* Bring-your-own AI model

---

## Vision

Omnichannel AI across:

* CLI
* VS Code
* Azure Portal

---

## Final thoughts

AKS AI ecosystem combines:

* Skills (knowledge)
* MCP (execution)
* CLI (experience)

Together, they enable:

* Faster troubleshooting
* Better decisions
* Scalable cloud operations

```

# AKS-MCP

[![SafeSkill 92/100](https://img.shields.io/badge/SafeSkill-92%2F100_Verified%20Safe-brightgreen)](https://safeskill.dev/scan/azure-aks-mcp)
The AKS-MCP is a Model Context Protocol (MCP) server that enables AI assistants
to interact with Azure Kubernetes Service (AKS) clusters. It serves as a bridge
between AI tools (like GitHub Copilot, Claude, and other MCP-compatible AI
assistants) and AKS, translating natural language requests into AKS operations
and returning the results in a format the AI tools can understand.

It allows AI tools to:

- Operate (CRUD) AKS resources
- Retrieve details related to AKS clusters (VNets, Subnets, NSGs, Route Tables, etc.)
- Manage Azure Fleet operations for multi-cluster scenarios

## How it works

AKS-MCP connects to Azure using the Azure SDK and provides a set of tools that
AI assistants can use to interact with AKS resources. It leverages the Model
Context Protocol (MCP) to facilitate this communication, enabling AI tools to
make API calls to Azure and interpret the responses.

## Azure CLI Authentication

AKS-MCP uses Azure CLI (az) for AKS operations. Azure CLI authentication is attempted in this order:

1. Service Principal (client secret): When `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID` environment variables are present, a service principal login is performed using the following command: `az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID`

1. Workload Identity (federated token): When `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_FEDERATED_TOKEN_FILE` environment variables are present, a federated token login is performed using the following command: `az login --service-principal -u CLIENT_ID --tenant TENANT_ID --federated-token TOKEN`

1. User-assigned Managed Identity (managed identity client ID): When only `AZURE_CLIENT_ID` environment variable is present, a user-assigned managed identity login is performed using the following command: `az login --identity -u CLIENT_ID`

1. System-assigned Managed Identity: When `AZURE_MANAGED_IDENTITY` is set to `system`, a system-assigned managed identity login is performed using the following command: `az login --identity`

1. Existing Login: When none of the above environment variables are set, AKS-MCP assumes you have already authenticated (for example, via `az login`) and uses the existing session.

Optional subscription selection:

- If `AZURE_SUBSCRIPTION_ID` is set, AKS-MCP will run `az account set --subscription SUBSCRIPTION_ID` after login.

Notes and security:

- The federated token file must be exactly `/var/run/secrets/azure/tokens/azure-identity-token` and is strictly validated; other paths are rejected.
- After each login, AKS-MCP verifies authentication with `az account show --query id -o tsv`.
- Ensure the Azure CLI is installed and on PATH.

Environment variables used:

- `AZURE_TENANT_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_FEDERATED_TOKEN_FILE`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_MANAGED_IDENTITY` (set to `system` to opt into system-assigned managed identity)

## Available Tools

The AKS-MCP server provides consolidated tools for interacting with AKS
clusters. By default, the server uses **unified tools** (`call_az` for Azure operations and `call_kubectl` for Kubernetes operations) which provide a more flexible interface. For backward compatibility, you can enable **legacy specialized tools** by setting the environment variable `USE_LEGACY_TOOLS=true`.

Some tools will require read-write or admin permissions to run debugging pods on your cluster. To enable read-write or admin permissions for the AKS-MCP server, add the **access level** parameter to your MCP configuration file:

1. Navigate to your **mcp.json** file, or go to MCP: List Servers -> AKS-MCP -> Show Configuration Details in the **Command Palette** (For VSCode; `Ctrl+Shift+P` on Windows/Linux or `Cmd+Shift+P` on macOS).
2. In the "args" section of AKS-MCP, add the following parameters: "--access-level", "readwrite" / "admin"

For example:
```
"args": [
  "--transport",
  "stdio",
  "--access-level",
  "readwrite"
]
```

These tools have been designed to provide comprehensive functionality
through unified interfaces:

<details>
<summary>Azure CLI Operations (Unified Tool)</summary>

**Tool:** `call_az` *(default, available when `USE_LEGACY_TOOLS` is not set or set to `false`)*

Unified tool for executing Azure CLI commands directly. This tool provides a flexible interface to run any Azure CLI command.

**Parameters:**
- `cli_command`: The complete Azure CLI command to execute (e.g., `az aks list --resource-group myRG`, `az vm list --subscription <sub-id>`)
- `timeout`: Optional timeout in seconds (default: 120)

**Example Usage:**
```json
{
  "cli_command": "az aks list --resource-group myResourceGroup --output json"
}
```

**Access Control:**
- **readonly**: Only read operations are allowed
- **readwrite/admin**: Both read and write operations are allowed

**Important:** Commands must be simple Azure CLI invocations without shell features like pipes (|), redirects (>, <), command substitution, or semicolons (;).

</details>

<details>
<summary>AKS Cluster Management (Legacy Tool)</summary>

**Tool:** `az_aks_operations` *(available when `USE_LEGACY_TOOLS=true`)*

Unified tool for managing Azure Kubernetes Service (AKS) clusters and related operations.

**Available Operations:**

- **Read-Only** (all access levels):
  - `show`: Show cluster details
  - `list`: List clusters in subscription/resource group
  - `get-versions`: Get available Kubernetes versions
  - `check-network`: Perform outbound network connectivity check
  - `nodepool-list`: List node pools in cluster
  - `nodepool-show`: Show node pool details
  - `account-list`: List Azure subscriptions

- **Read-Write** (`readwrite`/`admin` access levels):
  - `create`: Create new cluster
  - `delete`: Delete cluster
  - `scale`: Scale cluster node count
  - `start`: Start a stopped cluster
  - `stop`: Stop a running cluster
  - `update`: Update cluster configuration
  - `upgrade`: Upgrade Kubernetes version
  - `nodepool-add`: Add node pool to cluster
  - `nodepool-delete`: Delete node pool
  - `nodepool-scale`: Scale node pool
  - `nodepool-upgrade`: Upgrade node pool
  - `account-set`: Set active subscription
  - `login`: Azure authentication

- **Admin-Only** (`admin` access level):
  - `get-credentials`: Get cluster credentials for kubectl access

</details>

<details>
<summary>Network Resource Management</summary>

**Tool:** `aks_network_resources`

Unified tool for getting Azure network resource information used by AKS clusters.

**Available Resource Types:**

- `all`: Get information about all network resources
- `vnet`: Virtual Network information
- `subnet`: Subnet information
- `nsg`: Network Security Group information
- `route_table`: Route Table information
- `load_balancer`: Load Balancer information
- `private_endpoint`: Private endpoint information

</details>

<details>
<summary>Monitoring and Diagnostics</summary>

**Tool:** `aks_monitoring`

Unified tool for Azure monitoring and diagnostics operations for AKS clusters.

**Available Operations:**

- `metrics`: List metric values for resources
- `resource_health`: Retrieve resource health events for AKS clusters
- `app_insights`: Execute KQL queries against Application Insights telemetry data
- `diagnostics`: Check if AKS cluster has diagnostic settings configured
- `control_plane_logs`: Query AKS control plane logs with safety constraints
  and time range validation

</details>

<details>
<summary>Compute Resources</summary>

**Tool:** `get_aks_vmss_info`

- Get detailed VMSS configuration for node pools in the AKS cluster

**Tool:** `collect_aks_node_logs`

Collect system logs from AKS VMSS nodes for debugging and troubleshooting.

**Parameters:**
- `aks_resource_id`: AKS cluster resource ID
- `vmss_name`: VMSS name (obtain from `get_aks_vmss_info` or `kubectl get nodes`)
- `instance_id`: VMSS instance ID
- `log_type`: Type of logs to collect (`kubelet`, `containerd`, `kernel`, `syslog`)
- `lines`: Number of recent log lines to return (default: 500, max: 2000)
- `since`: Time range for logs (e.g., `1h`, `30m`, `2d`) - takes precedence over `lines`
- `level`: Log level filter (`ERROR`, `WARN`, `INFO`)
- `filter`: Filter logs by keyword (case-insensitive text match)

**Example Usage:**
```json
{
  "aks_resource_id": "/subscriptions/.../managedClusters/myAKS",
  "vmss_name": "aks-nodepool1-12345678-vmss",
  "instance_id": "0",
  "log_type": "kubelet",
  "since": "1h",
  "level": "ERROR",
  "filter": "ImagePullBackOff"
}
```

**Limitations:**
- Only supports Linux VMSS nodes (Windows nodes and standalone VMs are not supported yet)
- Only one run command can execute at a time per VMSS instance

**Tool:** `az_compute_operations`

Unified tool for managing Azure Virtual Machines (VMs) and Virtual Machine Scale Sets (VMSS) used by AKS.

**Available Operations:**

- `show`: Get details of a VM/VMSS
- `list`: List VMs/VMSS in subscription or resource group
- `get-instance-view`: Get runtime status
- `start`: Start VM
- `stop`: Stop VM
- `restart`: Restart VM/VMSS instances
- `reimage`: Reimage VMSS instances (VM not supported for reimage)

**Resource Types:** `vm` (single virtual machines), `vmss` (virtual machine scale sets)

</details>

<details>
<summary>Fleet Management</summary>

**Tool:** `az_fleet`

Comprehensive Azure Fleet management for multi-cluster scenarios.

**Available Operations:**

- **Fleet Operations**: list, show, create, update, delete, get-credentials
- **Member Operations**: list, show, create, update, delete
- **Update Run Operations**: list, show, create, start, stop, delete
- **Update Strategy Operations**: list, show, create, delete
- **ClusterResourcePlacement Operations**: list, show, get, create, delete

Supports both Azure Fleet management and Kubernetes ClusterResourcePlacement
CRD operations.

</details>

<details>
<summary>Diagnostic Detectors</summary>

**Tool:** `aks_detector`

Unified tool for executing AKS diagnostic detector operations.

**Available Operations:**

- `list`: List all available AKS cluster detectors
- `run`: Run a specific AKS diagnostic detector
- `run_by_category`: Run all detectors in a specific category

**Parameters:**

- `operation` (required): Operation to perform (`list`, `run`, or `run_by_category`)
- `aks_resource_id` (required): AKS cluster resource ID
- `detector_name` (required for `run` operation): Name of the detector to run
- `category` (required for `run_by_category` operation): Detector category
- `start_time` (required for `run` and `run_by_category` operations): Start time in UTC ISO format (within last 30 days)
- `end_time` (required for `run` and `run_by_category` operations): End time in UTC ISO format (within last 30 days, max 24h from start)

**Available Categories:**

- Best Practices
- Cluster and Control Plane Availability and Performance
- Connectivity Issues
- Create, Upgrade, Delete and Scale
- Deprecations
- Identity and Security
- Node Health
- Storage

**Example Usage:**

```json
{
  "operation": "list",
  "aks_resource_id": "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.ContainerService/managedClusters/xxx"
}
```

```json
{
  "operation": "run",
  "aks_resource_id": "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.ContainerService/managedClusters/xxx",
  "detector_name": "node-health-detector",
  "start_time": "2025-01-15T10:00:00Z",
  "end_time": "2025-01-15T12:00:00Z"
}
```

</details>

<details>
<summary>Azure Advisor</summary>

**Tool:** `aks_advisor_recommendation`

Retrieve and manage Azure Advisor recommendations for AKS clusters.

**Available Operations:**

- `list`: List recommendations with filtering options
- `report`: Generate recommendation reports
- **Filter Options**: resource_group, cluster_names, category (Cost,
  HighAvailability, Performance, Security), severity (High, Medium, Low)

</details>

<details>
<summary>Kubernetes Operations</summary>

*Note: All Kubernetes tools (kubectl, helm, cilium, hubble) are enabled by default. Use `--enabled-components` to selectively enable specific components.*

### Unified kubectl Tool (Default)

**Tool:** `call_kubectl` *(default, available when `USE_LEGACY_TOOLS` is not set or set to `false`)*

Unified tool for executing kubectl commands directly. This tool provides a flexible interface to run any `kubectl` command with full argument support.

**Parameters:**
- `args`: The kubectl command arguments (e.g., `get pods`, `describe node mynode`, `apply -f deployment.yaml`)

**Example Usage:**
```json
{
  "args": "get pods -n kube-system -o wide"
}
```

**Access Control:** Operations are restricted based on the configured access level:
- **readonly**: Only read operations (get, describe, logs, etc.) are allowed
- **readwrite/admin**: All operations including mutating commands (create, delete, apply, etc.)

### Legacy kubectl Tools (Specialized)

**Available when `USE_LEGACY_TOOLS=true`:**

- **Read-Only** (all access levels):
  - `kubectl_resources`: View resources (get, describe) - filtered to read-only operations in readonly mode
  - `kubectl_diagnostics`: Debug and diagnose (logs, events, top, exec, cp)
  - `kubectl_cluster`: Cluster information (cluster-info, api-resources, api-versions, explain)
  - `kubectl_config`: Configuration management (diff, auth, config) - filtered to read-only operations in readonly mode

- **Read-Write/Admin** (`readwrite`/`admin` access levels):
  - `kubectl_resources`: Full resource management (get, describe, create, delete, apply, patch, replace, cordon, uncordon, drain, taint)
  - `kubectl_workloads`: Workload lifecycle (run, expose, scale, autoscale, rollout)
  - `kubectl_metadata`: Metadata management (label, annotate, set)
  - `kubectl_config`: Full configuration management (diff, auth, certificate, config)

### Helm

**Tool:** `call_helm`

Helm package manager for Kubernetes.

### Cilium

**Tool:** `call_cilium`

Cilium CLI for eBPF-based networking and security.

### Hubble

**Tool:** `call_hubble`

Hubble network observability for Cilium.

</details>

<details>
<summary>Real-time Observability</summary>

**Tool:** `inspektor_gadget_observability`

Real-time observability tool for Azure Kubernetes Service (AKS) clusters using
eBPF.

**Available Actions:**

- `deploy`: Deploy Inspektor Gadget to cluster
- `undeploy`: Remove Inspektor Gadget from cluster
- `is_deployed`: Check deployment status
- `run`: Run one-shot gadgets
- `start`: Start continuous gadgets
- `stop`: Stop running gadgets
- `get_results`: Retrieve gadget results
- `list_gadgets`: List available gadgets

**Available Gadgets:**

- `observe_dns`: Monitor DNS requests and responses
- `observe_tcp`: Monitor TCP connections
- `observe_file_open`: Monitor file system operations
- `observe_process_execution`: Monitor process execution
- `observe_signal`: Monitor signal delivery
- `observe_system_calls`: Monitor system calls
- `top_file`: Top files by I/O operations
- `top_tcp`: Top TCP connections by traffic
- `tcpdump`: Capture network packets

</details>

## How to install

### Prerequisites

1. Set up [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and authenticate:

   ```bash
   az login
   ```

### VS Code with GitHub Copilot (Recommended)

<details>
<summary> One-Click Installation with the AKS Extension </summary>

The easiest way to get started with AKS-MCP is through the **Azure Kubernetes Service Extension for VS Code**.

#### Step 1: Install the AKS Extension

1. Open VS Code and go to Extensions (`Ctrl+Shift+X` on Windows/Linux or `Cmd+Shift+X` on macOS).
1. Search for [Azure Kubernetes Service](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-aks-tools).
1. Install the official Microsoft AKS extension.

#### Step 2: Launch the AKS-MCP Server

1. Open the **Command Palette** (`Ctrl+Shift+P` on Windows/Linux or `Cmd+Shift+P` on macOS).
2. Search and run: **AKS: Setup AKS MCP Server**.

Upon successful installation, the server will now be visible in **MCP: List Servers** (via Command Palette). From there, you can start the MCP server or view its status.

#### Step 3: Start Using AKS-MCP

Once started, the MCP server will appear in the **Copilot Chat: Configure Tools** dropdown under `MCP Server: AKS MCP`, ready to enhance contextual prompts based on your AKS environment. By default, all AKS-MCP server tools are enabled. You can review the list of available tools and disable any that are not required for your specific scenario.

Try a prompt like *"List all my AKS clusters"*, which will start using tools from the AKS-MCP server.

#### WSL Configuration

The MCP configuration differs depending on whether VS Code is running on Windows or inside WSL:

**🪟 Windows Host (VS Code on Windows)**: Use `"command": "wsl"` to invoke the WSL binary from Windows:

```json
{
  "servers": {
    "aks-mcp": {
      "type": "stdio",
      "command": "wsl",
      "args": [
        "--",
        "/home/you/.vs-kubernetes/tools/aks-mcp/aks-mcp",
        "--transport",
        "stdio"
      ]
    }
  }
}
```

**🐧 Remote-WSL (VS Code running inside WSL)**: Call the binary directly or use a shell wrapper:

```json
{
  "servers": {
    "aks-mcp": {
      "type": "stdio",
      "command": "bash",
      "args": [
        "-c",
        "/home/you/.vs-kubernetes/tools/aks-mcp/aks-mcp --transport stdio"
      ]
    }
  }
}
```


**🔧 Troubleshooting ENOENT Errors**

If you see "spawn ENOENT" errors, verify your VS Code environment:
- **Windows host**: Check if the WSL binary path is correct and accessible via `wsl -- ls /path/to/aks-mcp`
- **Remote-WSL**: Do NOT use `"command": "wsl"` - use direct paths or bash wrapper as shown above
</details>

> **💡 Benefits**: The AKS extension handles binary downloads, updates, and configuration automatically, ensuring you always have the latest version with optimal settings.


### Deploy the MCP server in-cluster (Remote MCP)
<details>
<summary> Remote MCP Installation </summary>
To enable the remote AKS MCP server in your AKS cluster, see the instructions below:

1. Helm chart installation with OAuth-based access: [Helm Chart](https://github.com/Azure/aks-mcp/tree/main/chart)

2. Helm chart installation with RBAC (Workload Identity): [Blog Post - Deploy AKS MCP server with Workload Identity](https://blog.aks.azure.com/2025/10/22/deploy-mcp-server-aks-workload-identity)
   
</details>


### Alternative Installation Methods

<details>
<summary>Manual Binary Installation</summary>

#### Step 1: Download the Binary

Choose your platform and download the latest AKS-MCP binary:

| Platform | Architecture | Download Link |
|----------|-------------|---------------|
| **Windows** | AMD64 | [📥 aks-mcp-windows-amd64.exe](https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-windows-amd64.exe) |
| | ARM64 | [📥 aks-mcp-windows-arm64.exe](https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-windows-arm64.exe) |
| **macOS** | Intel (AMD64) | [📥 aks-mcp-darwin-amd64](https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-darwin-amd64) |
| | Apple Silicon (ARM64) | [📥 aks-mcp-darwin-arm64](https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-darwin-arm64) |
| **Linux** | AMD64 | [📥 aks-mcp-linux-amd64](https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-linux-amd64) |
| | ARM64 | [📥 aks-mcp-linux-arm64](https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-linux-arm64) |

#### Step 2: Configure VS Code

After downloading, create a `.vscode/mcp.json` file in your workspace root with the path to your downloaded binary.

##### Option A: Automated Setup Script

For quick setup, you can use these one-liner scripts that download the binary
and create the configuration:

*Windows (PowerShell):*

```powershell
# Download binary and create VS Code configuration
mkdir -p .vscode ; Invoke-WebRequest -Uri "https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-windows-amd64.exe" -OutFile "aks-mcp.exe" ; @{servers=@{"aks-mcp-server"=@{type="stdio";command="$PWD\aks-mcp.exe";args=@("--transport","stdio")}}} | ConvertTo-Json -Depth 3 | Out-File ".vscode/mcp.json" -Encoding UTF8
```

*macOS/Linux (Bash):*

```bash
# Download binary and create VS Code configuration
mkdir -p .vscode && curl -sL https://github.com/Azure/aks-mcp/releases/latest/download/aks-mcp-linux-amd64 -o aks-mcp && chmod +x aks-mcp && echo '{"servers":{"aks-mcp-server":{"type":"stdio","command":"'$PWD'/aks-mcp","args":["--transport","stdio"]}}}' > .vscode/mcp.json
```

##### Option B: Manual Configuration

> **✨ Simple Setup**: Download the binary for your platform, then use the manual configuration below to set up the MCP server in VS Code.

#### Manual VS Code Configuration

You can configure the AKS-MCP server in two ways:

**1. Workspace-specific configuration** (recommended for project-specific usage):

Create a `.vscode/mcp.json` file in your workspace with the path to your downloaded binary:

```json
{
  "servers": {
    "aks-mcp-server": {
      "type": "stdio",
      "command": "<enter the file path>",
      "args": [
        "--transport", "stdio"
      ]
    }
  }
}
```

**2. User-level configuration** (persistent across all workspaces):

For a persistent configuration that works across all your VS Code workspaces, add the MCP server to your VS Code user settings:

1. Open VS Code Settings (Ctrl+, or Cmd+,)
2. Search for "mcp" in the settings
3. Add the following to your User Settings JSON:

```json
{
  "github.copilot.chat.mcp.servers": {
    "aks-mcp-server": {
      "type": "stdio",
      "command": "<enter the file path>",
      "args": [
        "--transport", "stdio"
      ]
    }
  }
}
```

#### Step 3: Load the AKS-MCP server tools to Github Copilot

1. If running on an older version of VS Code: restart VS Code i.e. close and
   reopen VS Code to load the new MCP server configuration.
2. Open GitHub Copilot in VS Code and [switch to Agent mode](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
3. Click the **Tools** button or run /list in the Github Copilot window to see the list of available tools
4. You should see the AKS-MCP tools in the list
5. Try a prompt like: *"List all my AKS clusters in subscription xxx"*
6. The agent will automatically use AKS-MCP tools to complete your request

> **💡 Tip**: If you don't see the AKS-MCP tools after restarting, check the VS Code output panel for any MCP server connection errors and verify your binary path in `.vscode/mcp.json`.

**Note**: Ensure you have authenticated with Azure CLI (`az login`) for the server to access your Azure resources.

</details>

### Other MCP-Compatible Clients

<details>
<summary>Docker and Custom Client Installation</summary>

For other MCP-compatible AI clients like [Claude Desktop](https://claude.ai/) or [GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli), configure the server in your MCP configuration:

```json
{
  "mcpServers": {
    "aks": {
      "command": "<path of binary aks-mcp>",
      "args": [
        "--transport", "stdio"
      ]
    }
  }
}
```

#### 🐳 Docker MCP Toolkit

You can enable the [AKS-MCP server directly from MCP Toolkit](https://hub.docker.com/mcp/server/aks/overview):

1. Open Docker Desktop
2. Click "MCP Toolkit" in the left sidebar
3. Search for "aks" in Catalog tab
4. Click on the AKS-MCP server card
5. Enable the server by clicking "+" in the top right corner
6. Configure the server using "Configuration" tab:
   - **azure_dir** `[REQUIRED]`: Path to your Azure credentials directory e.g `/home/user/.azure` (must be absolute – without `$HOME` or `~`)
   - **kubeconfig** `[REQUIRED]`: Path to your kubeconfig file e.g `/home/user/.kube/config` (must be absolute – without `$HOME` or `~`)
   - **access_level** `[REQUIRED]`: Set to `readonly`, `readwrite`, or `admin` as needed
   - **container_user** `[OPTIONAL]`: Username or UID to run the container as (default is `mcp`), e.g. use `1000` to match your host user ID (see note below). Only needed if you are using docker engine on Linux.
7. You are now ready to use the AKS-MCP server with your [preferred MCP client](https://hub.docker.com/mcp/server/aks/manual), see an example [here](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/#install-an-mcp-client). (requires `>= v0.16.0` for MCP gateway)

> **Note**: When running the MCP gateway using Docker Engine, you have to set the `container_user` to match your host user ID (e.g using `id -u`) to ensure proper file permissions for accessing mounted volumes.
> On Docker Desktop, this is handled automatically if you use `desktop-*` contexts, confirmed by running `docker context ls`.

On **Windows**, the Azure credentials won't work by default, but you have two options:

1. **Long-lived servers**: Configure the [MCP gateway](https://docs.docker.com/ai/mcp-gateway/) to use long-lived servers using `--long-lived` flag and then authenticate with Azure CLI in the container, see option B in Containerized MCP configuration below on how to fetch credentials inside the container. 
2. **Custom Azure Directory**: Set up a custom Azure directory:
    ```powershell
    # Set custom Azure config directory
    $env:AZURE_CONFIG_DIR = "$env:USERPROFILE\.azure-for-docker"
    
    # Disable token cache encryption (to match behavior with Linux/macOS)
    $env:AZURE_CORE_ENCRYPT_TOKEN_CACHE = "false"
    
    # Login to Azure CLI
    az login
    ```

   This will store the credentials in `$env:USERPROFILE\.azure-for-docker` (e.g. `C:\Users\<username>\.azure-for-docker`),
   use this path in the AKS-MCP server configuration `azure_dir`.

You can also use the [MCP Gateway](https://docs.docker.com/ai/mcp-gateway/) to enable the AKS-MCP server directly using:

```bash
# Enable AKS-MCP server in Docker MCP Gateway
docker mcp server enable aks
```

Note: You still need to configure the server (e.g. using `docker mcp config`) with your Azure credentials, kubeconfig file, and access level.

#### 🐋 Containerized MCP configuration

For containerized deployment, you can run AKS-MCP server using the official Docker image:

Option A: Mount credentials from host (recommended):

```json
{
  "mcpServers": {
    "aks": {
      "type": "stdio",
      "command": "docker",
      "args": [
          "run",
          "-i",
          "--rm",
          "--user",
          "<your-user-id (e.g. id -u)>",
          "-v",
          "~/.azure:/home/mcp/.azure",
          "-v",
          "~/.kube:/home/mcp/.kube",
          "ghcr.io/azure/aks-mcp:latest",
          "--transport",
          "stdio"
        ]
    }
  }
}
```

Option B: fetch the credentials inside the container:

```json
{
  "mcpServers": {
    "aks": {
      "type": "stdio",
      "command": "docker",
      "args": [
          "run",
          "-i",
          "--rm",
          "ghcr.io/azure/aks-mcp:latest",
          "--transport",
          "stdio"
        ]
    }
  }
}
```

Start the MCP server container first per above command, and then run the following commands to fetch the credentials:
- Login to Azure CLI: `docker exec -it <container-id> az login --use-device-code`
- Get kubeconfig: `docker exec -it <container-id> az aks get-credentials -g <resource-group> -n <cluster-name>`

Note that:

- Host Azure CLI logins don’t automatically propagate into containers without mounting `~/.azure`.
- User ID should be set for option A, orelse the mcp user inside container won't be able to access the mounted files.

### 🤖 Custom MCP Client Installation

You can configure any MCP-compatible client to use the AKS-MCP server by running the binary directly:

```bash
# Run the server directly
./aks-mcp --transport stdio
```

### 🔧 Manual Binary Installation

For direct binary usage without package managers:

1. Download the latest release from the [releases page](https://github.com/Azure/aks-mcp/releases)
2. Extract the binary to your preferred location
3. Make it executable (on Unix systems):
   ```bash
   chmod +x aks-mcp
   ```
4. Configure your MCP client to use the binary path

</details>

### Options

Command line arguments:

```sh
Usage of ./aks-mcp:
      --access-level string       Access level (readonly, readwrite, admin) (default "readonly")
      --enabled-components string Comma-separated list of enabled components (empty means all components enabled). Available: az_cli,monitor,fleet,network,compute,detectors,advisor,inspektorgadget,kubectl,helm,cilium,hubble
      --allow-namespaces string   Comma-separated list of allowed Kubernetes namespaces (empty means all namespaces)
      --host string               Host to listen for the server (only used with transport sse or streamable-http) (default "127.0.0.1")
      --otlp-endpoint string      OTLP endpoint for OpenTelemetry traces (e.g. localhost:4317, default "")
      --port int                  Port to listen for the server (only used with transport sse or streamable-http) (default 8000)
      --timeout int               Timeout for command execution in seconds, default is 600s (default 600)
      --transport string          Transport mechanism to use (stdio, sse or streamable-http) (default "stdio")
      --log-level string          Log level (debug, info, warn, error) (default "info")
```

**Environment variables:**
- `USE_LEGACY_TOOLS`: Set to `true` to use legacy specialized tools instead of unified tools (default: `false`)
  - `false` (default): Uses `call_az` for Azure operations and `call_kubectl` for Kubernetes operations
  - `true`: Uses legacy tools like `az_aks_operations`, `az_compute_operations`, and specialized kubectl tools
- Standard Azure authentication environment variables are supported (`AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID`)

## Development

### Prerequisites

- **Go** ≥ `1.24.x` installed on your local machine
- **Bash** available as `/usr/bin/env bash` (Makefile targets use multi-line recipes with fail-fast mode)
- **GNU Make** `4.x` or later
- **Docker** *(optional, for container builds and testing)*

> **Note:** If your login shell is different (e.g., `zsh` on **macOS**), you do **not** need to change it — the Makefile sets variables to run all recipes in `bash` for consistent behavior across platforms.

### Building from Source

This project includes a Makefile for convenient development, building, and testing. To see all available targets:

```bash
make help
```

#### Quick Start

```bash
# Build the binary
make build

# Run tests
make test

# Run tests with coverage
make test-coverage

# Format and lint code
make check

# Build for all platforms
make release
```

#### Common Development Tasks

```bash
# Install dependencies
make deps

# Build and run with --help
make run

# Clean build artifacts
make clean

# Install binary to GOBIN
make install
```

#### Docker

```bash
# Build Docker image
make docker-build

# Run Docker container
make docker-run
```

### Manual Build

If you prefer to build without the Makefile:

```bash
go build -o aks-mcp ./cmd/aks-mcp
```

## Usage

Ask any questions about your AKS clusters in your AI client, for example:

```
List all my AKS clusters in my subscription xxx.

What is the network configuration of my AKS cluster?

Show me the network security groups associated with my cluster.

Create a new Azure Fleet named prod-fleet in eastus region.

List all members in my fleet.

Create a placement to deploy nginx workloads to clusters with app=frontend label.

Show me all ClusterResourcePlacements in my fleet.
```

## Telemetry

Telemetry collection is on by default.

To opt out, set the environment variable `AKS_MCP_COLLECT_TELEMETRY=false`.

## Contributing

We welcome contributions to AKS-MCP! Whether you're fixing bugs, adding features, or improving documentation, your help makes this project better.

**📖 [Read our detailed Contributing Guide](CONTRIBUTING.md)** for comprehensive information on:

- Setting up your development environment
- Running AKS-MCP locally and testing with AI agents
- Understanding the codebase architecture
- Adding new MCP tools and features
- Testing guidelines and best practices
- Submitting pull requests

### Quick Start for Contributors

1. **Prerequisites**: Go ≥ 1.24.x, Azure CLI, Git
2. **Setup**: Fork the repo, clone locally, run `make deps && make build`
3. **Test**: Run `make test` and `make check`
4. **Develop**: Follow the component-based architecture in [CONTRIBUTING.md](CONTRIBUTING.md)

### Contributor License Agreement

Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.


# Containerization Assist MCP Server

[![Test Pipeline](https://github.com/Azure/containerization-assist/actions/workflows/test-pipeline.yml/badge.svg?branch=main)](https://github.com/Azure/containerization-assist/actions/workflows/test-pipeline.yml)
[![Version](https://img.shields.io/github/package-json/v/Azure/containerization-assist?color=orange)](https://github.com/Azure/containerization-assist/releases)
[![MCP SDK](https://img.shields.io/github/package-json/dependency-version/Azure/containerization-assist/@modelcontextprotocol/sdk?color=blueviolet&label=MCP%20SDK)](https://github.com/modelcontextprotocol/typescript-sdk)
[![Node](https://img.shields.io/github/package-json/engines-node/Azure/containerization-assist?color=brightgreen&label=node)](https://nodejs.org)
[![TypeScript](https://img.shields.io/github/package-json/dependency-version/Azure/containerization-assist/dev/typescript?color=blue&label=TypeScript)](https://www.typescriptlang.org/)
[![License](https://img.shields.io/github/license/Azure/containerization-assist?color=green)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://azure.github.io/containerization-assist/)

An AI-powered containerization assistant that helps you build, scan, and deploy Docker containers through VS Code and other MCP-compatible tools.

> **[Full documentation →](https://azure.github.io/containerization-assist/)**

## Install


[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install_Containerization_Assist_MCP-0098FF?style=flat-square&logo=visualstudiocode&logoColor=ffffff)](https://insiders.vscode.dev/redirect/mcp/install?name=containerization-assist&config=%7B%22type%22%3A%22stdio%22%2C%22command%22%3A%22npx%22%2C%22args%22%3A%5B%22-y%22%2C%22containerization-assist-mcp%22%2C%22start%22%5D%7D)
[![Install in VS Code Insiders](https://img.shields.io/badge/VS_Code_Insiders-Install_Containerization_Assist_MCP-24bfa5?style=flat-square&logo=visualstudiocode&logoColor=ffffff)](https://insiders.vscode.dev/redirect/mcp/install?name=containerization-assist&config=%7B%22type%22%3A%22stdio%22%2C%22command%22%3A%22npx%22%2C%22args%22%3A%5B%22-y%22%2C%22containerization-assist-mcp%22%2C%22start%22%5D%7D&quality=insiders)

## Features

### Core Capabilities

- 🐳 **Docker Integration**: Build, scan, and deploy container images
- ☸️ **Kubernetes Support**: Generate manifests and deploy applications
- 🤖 **AI-Powered**: Intelligent Dockerfile generation and optimization
- 🧠 **Knowledge Enhanced**: AI-driven content improvement with security and performance best practices
- 🔄 **Intelligent Tool Routing**: Automatic dependency resolution and execution
- 📊 **Progress Tracking**: Real-time progress updates via MCP notifications
- 🔒 **Security Scanning**: Built-in vulnerability scanning with AI-powered suggestions
- ✨ **Smart Analysis**: Context-aware recommendations
- **Policy-Driven System (v3.0)**
  - Pre-generation configuration
  - Knowledge filtering and weighting
  - Template injection
  - Semantic validation
  - Cross-tool consistency

### Policy System (v3.0)

Full control over containerization through Rego policies:

- **Configure Before Generation**: Set defaults for resources, base images, build strategy
- **Guide During Generation**: Filter knowledge base, inject templates automatically
- **Validate After Generation**: Semantic checks, security scoring, cross-tool consistency

**Example Policies Included**:
- Environment-based strategy (dev/staging/prod)
- Cost control by team tier
- Security-first organization
- Multi-cloud registry governance
- Speed-optimized development

See [Policy Authoring Guide](docs/guides/policy-authoring.md) for details.

## System Requirements

- Node.js 20+
- Docker or Docker Desktop
- Optional: [Trivy](https://aquasecurity.github.io/trivy/latest/getting-started/installation/) (for security scanning features)
- Optional: Kubernetes (for deployment features)

## Manual Install

Add the following to your VS Code settings or create `.vscode/mcp.json` in your project:

```json
{
  "servers": {
    "ca": {
      "command": "npx",
      "args": ["-y", "containerization-assist-mcp", "start"],
      "env": {
         "LOG_LEVEL": "info"
      }
    }
  }
}
```

Restart VS Code to enable the MCP server in GitHub Copilot.

### SDK Usage (Without MCP)

For direct tool usage without MCP protocol (e.g., VS Code extensions, programmatic access):

```typescript
import { analyzeRepo, buildImageContext, scanImage } from 'containerization-assist-mcp/sdk';
import { execSync } from 'child_process';

// Simple function calls - no MCP server needed
const analysis = await analyzeRepo({ repositoryPath: './myapp' });
if (analysis.ok) {
  console.log('Detected:', analysis.value.modules);
}

// buildImageContext returns build context with security analysis and commands
const buildContext = await buildImageContext({ path: './myapp', imageName: 'myapp:v1', platform: 'linux/amd64' });
if (buildContext.ok) {
  const { securityAnalysis, nextAction } = buildContext.value;
  console.log('Security risk:', securityAnalysis.riskLevel);
  
  // Execute the generated build command from the build context directory
  execSync(nextAction.buildCommand.command, {
    cwd: buildContext.value.context.buildContextPath,
    env: { ...process.env, ...nextAction.buildCommand.environment }
  });
}

const scan = await scanImage({ imageId: 'myapp:v1' });
```

See the [SDK integration examples](docs/examples/README.md) for full SDK documentation.

### Windows Users

For Windows, use the Windows Docker pipe:
```json
"DOCKER_SOCKET": "//./pipe/docker_engine"
```

## Quick Start

The easiest way to understand the containerization workflow is through an end-to-end example:

### Single-App Containerization Journey

This MCP server guides you through a complete containerization workflow for a single application. The journey follows this sequence:

1. **Analyze Repository** → Understand your application's language, framework, and dependencies
2. **Generate Dockerfile** → Create an optimized, security-hardened container configuration
3. **Build Image** → Compile your application into a Docker image
4. **Scan Image** → Identify security vulnerabilities and get remediation guidance
5. **Tag Image** → Apply appropriate version tags to your image
6. **Generate K8s Manifests** → Create deployment configurations for Kubernetes
7. **Prepare Cluster** → Set up namespace and prerequisites, then deploy with `kubectl apply`
8. **Verify** → Confirm deployment health and readiness

### Prerequisites

Before starting, ensure you have:

- **Docker**: Running Docker daemon with accessible socket (`docker ps` should work)
  - Linux/Mac: `/var/run/docker.sock` accessible
  - Windows: Docker Desktop with `//./pipe/docker_engine` accessible
- **Kubernetes** (optional, for deployment features):
  - Valid kubeconfig at `~/.kube/config`
  - Cluster connectivity (`kubectl cluster-info` should work)
  - Appropriate RBAC permissions for deployments, services, namespaces
- **Node.js**: Version 20 or higher
- **MCP Client**: VS Code with Copilot, Claude Desktop, or another MCP-compatible client

### Example Workflow with Natural Language

Once configured in your MCP client (VS Code Copilot, Claude Desktop, etc.), use natural language:

**Starting the Journey:**
```
"Analyze my Java application for containerization"
```

**Building the Container:**
```
"Generate an optimized Dockerfile with security best practices"
"Build a Docker image tagged myapp:v1.0.0"
"Scan the image for vulnerabilities"
```

**Deploying to Kubernetes:**
```
"Generate Kubernetes manifests for this application"
"Prepare my cluster and deploy to the default namespace"
"Verify the deployment is healthy"
```

### Single-Operator Model

This server is optimized for **one engineer containerizing one application at a time**. Key characteristics:

- **Sequential execution**: Each tool builds on the results of previous steps
- **Fast-fail validation**: Clear, actionable error messages if Docker/Kubernetes are unavailable
- **Deterministic AI generation**: Tools provide reproducible outputs through built-in prompt engineering
- **Real-time progress**: MCP notifications surface progress updates to clients during long-running operations

### Multi-Module/Monorepo Support

The server detects and supports monorepo structures with multiple independently deployable services:

- **Automatic Detection**: `analyze-repo` identifies monorepo patterns (npm workspaces, services/, apps/ directories)
- **Automated Multi-Module Generation**: `generate-dockerfile` and `generate-k8s-manifests` support multi-module workflows
- **Conservative Safeguards**: Excludes shared libraries and utility folders from containerization

**Multi-Module Workflow Example:**
```
1. "Analyze my monorepo at ./my-monorepo"
   → Detects 3 modules: api-gateway, user-service, notification-service

2. "Generate Dockerfiles"
   → Automatically creates Dockerfiles for all 3 modules:
     - services/api-gateway/Dockerfile
     - services/user-service/Dockerfile
     - services/notification-service/Dockerfile

3. "Generate K8s manifests"
   → Automatically creates manifests for all 3 modules

4. Optional: "Generate Dockerfile for user-service module"
   → Creates module-specific deployment manifests
```

**Detection Criteria:**
- Workspace configurations (npm, yarn, pnpm workspaces, lerna, nx, turborepo, cargo workspace)
- Separate package.json, pom.xml, go.mod, Cargo.toml per service
- Independent entry points and build configs
- EXCLUDES: shared/, common/, lib/, packages/utils directories

## Available Tools

The server provides 11 MCP tools organized by functionality:

### Analysis & Planning
| Tool | Description |
|------|-------------|
| `analyze-repo` | Analyze repository structure and detect technologies by parsing config files |

### Dockerfile Operations
| Tool | Description |
|------|-------------|
| `generate-dockerfile` | Gather insights from knowledge base and return requirements for Dockerfile creation |
| `fix-dockerfile` | Analyze Dockerfile for issues including organizational policy validation and return knowledge-based fix recommendations |

### Image Operations
| Tool | Description |
|------|-------------|
| `build-image-context` | Prepare Docker build context with security analysis and return build commands |
| `scan-image` | Scan Docker images for security vulnerabilities with remediation guidance (uses Trivy CLI) |
| `tag-image` | Tag Docker images with version and registry information |
| `push-image` | Push Docker images to a registry |

### Kubernetes Operations
| Tool | Description |
|------|-------------|
| `generate-k8s-manifests` | Gather insights and return requirements for Kubernetes/Helm/ACA/Kustomize manifest creation |
| `prepare-cluster` | Prepare Kubernetes cluster for deployment |
| `verify-deploy` | Verify Kubernetes deployment status |

### Utilities
| Tool | Description |
|------|-------------|
| `ops` | Operational utilities for ping and server status |

### Workflow Tools

Interactive workflow tools that return step-by-step plans (output is collapsed by default in VS Code Copilot Chat):

| Tool | Description | Inputs |
|------|-------------|--------|
| `create-containerization-policy` | Step-by-step guidance for authoring a custom OPA Rego policy | None |
| `kind-loop` | Local dev loop: analyze → build → scan → deploy to Kind | `namespace` (optional), `imageName` (optional) |
| `aks-loop` | Remote dev loop: analyze → build → push → deploy to AKS | `registry`, `resourceGroup`, `clusterName` (required); `namespace`, `imageName` (optional) |

## Supported Technologies

### Languages & Frameworks
- **Java**: Spring Boot, Quarkus, Micronaut (Java 8-21)
- **.NET**: ASP.NET Core, Blazor (.NET 6.0+)

### Build Systems
- Maven, Gradle (Java)
- dotnet CLI (.NET)

## Configuration

### Environment Variables

The following environment variables control server behavior:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DOCKER_SOCKET` | Docker socket path | `/var/run/docker.sock` (Linux/Mac)<br>`//./pipe/docker_engine` (Windows) | No  |
| `DOCKER_HOST` | Docker host URI (`unix://`, `tcp://`, `http://`, `https://`, `npipe://`) | Auto-detected | No |
| `DOCKER_TIMEOUT` | Docker operation timeout in milliseconds | `60000` (60s) | No |
| `KUBECONFIG` | Path to Kubernetes config file | `~/.kube/config` | No |
| `K8S_NAMESPACE` | Default Kubernetes namespace | `default` | No |
| `LOG_LEVEL` | Logging level | `info` | No |
| `WORKSPACE_DIR` | Working directory for operations | Current directory | No |
| `MCP_MODE` | Enable MCP protocol mode (logs to stderr) | `false` | No |
| `MCP_QUIET` | Suppress non-essential output in MCP mode | `false` | No |
| `CONTAINERIZATION_ASSIST_TOOL_LOGS_DIR_PATH` | Directory path for tool execution logs (JSON format) | Disabled | No |
| `CUSTOM_POLICY_PATH` | Directory path for custom policies (highest priority) | Not set | No |

**Progress Notifications:**
Long-running operations (build, deploy, scan-image) emit real-time progress updates via MCP notifications. MCP clients can subscribe to these notifications to display progress to users.

### Tool Execution Logging

Enable detailed logging of all tool executions to JSON files for debugging and auditing:

```bash
export CONTAINERIZATION_ASSIST_TOOL_LOGS_DIR_PATH=/path/to/logs
```

**Log File Format:**
- Filename: `ca-tool-logs-${timestamp}.jsonl`
- Example: `ca-tool-logs-2025-10-13T14-30-15-123Z.jsonl`

**Log Contents:**
```json
{
  "timestamp": "2025-10-13T14:30:15.123Z",
  "toolName": "analyze-repo",
  "input": { "path": "/workspace/myapp" },
  "output": { "language": "typescript", "framework": "express" },
  "success": true,
  "durationMs": 245,
  "error": "Error message if failed",
  "errorGuidance": {
    "hint": "Suggested fix",
    "resolution": "Step-by-step instructions"
  }
}
```

The logging directory is validated at startup to ensure it's writable.


### Policy System

The policy system uses **OPA Rego** for security, quality, and compliance enforcement. Rego is the industry-standard policy language from Open Policy Agent, providing expressive rules with rich built-in functions.

**Default Behavior (No Configuration Needed):**
By default, all policies in the `policies/` directory are automatically discovered and merged:
- `policies/security-baseline.rego` - Essential security rules (root user prevention, secrets detection, privileged containers)
- `policies/base-images.rego` - Base image governance (Microsoft Azure Linux recommendation, no :latest tag, deprecated versions)
- `policies/container-best-practices.rego` - Docker best practices (HEALTHCHECK, multi-stage builds, layer optimization)

This provides comprehensive out-of-the-box security and quality enforcement.

### Policy Customization

The policy system supports four priority-ordered search paths for easy customization:

**Priority Order (highest to lowest):**
1. **Custom directory** via `CUSTOM_POLICY_PATH` environment variable (highest priority)
2. **Project directory** at `<git-root>/.containerization-assist/policy/` (tracked in git)
3. **Global directory** at `~/.config/containerization-assist/policy/` (XDG-compliant)
4. **Built-in `policies/`** (shipped with package, lowest priority)

> **Migration Note**: The `policies.user/` directory is deprecated. For project-specific policies, use `.containerization-assist/policy/` at your git root. For user-wide policies, use `~/.config/containerization-assist/policy/`. The old directory still works but will log a deprecation warning.

#### Quick Start

```bash
# Option 1: Global policies (no env var needed)
mkdir -p ~/.config/containerization-assist/policy

# Copy example policy from the npm package
cp node_modules/containerization-assist-mcp/policies.user.examples/allow-all-registries.rego \
   ~/.config/containerization-assist/policy/

# Policies are auto-reloaded on the next tool execution — no restart needed
```

Or set a custom location in `.vscode/mcp.json`:

```json
{
  "servers": {
    "ca": {
      "env": {
        "CUSTOM_POLICY_PATH": "/path/to/policies"
      }
    }
  }
}
```

#### Pre-Built Example Policies

The `policies.user.examples/` directory (included in the npm package) provides three ready-to-use examples:

| Example | Purpose | Use Case |
|---------|---------|----------|
| `allow-all-registries.rego` | Override MCR preference | Docker Hub, GCR, ECR, private registries |
| `warn-only-mode.rego` | Advisory-only enforcement | Testing, gradual adoption, dev environments |
| `custom-organization-template.rego` | Organization template | Custom labels, registries, compliance |

See [policies.user.examples/README.md](policies.user.examples/README.md) for detailed usage.

#### Built-In Policies

Three production-ready Rego policies are included by default:

- **`policies/security-baseline.rego`** - Essential security rules (root user prevention, secrets detection, privileged containers)
- **`policies/base-images.rego`** - Base image governance (Microsoft Azure Linux recommendation, no :latest tag, deprecated versions)
- **`policies/container-best-practices.rego`** - Docker best practices (HEALTHCHECK, multi-stage builds, layer optimization)

User policies override built-in policies by package namespace.

**Policy File Format (Rego):**

```rego
package containerization.custom_policy

# Blocking violations
violations contains result if {
  input_type == "dockerfile"
  regex.match(`FROM\s+[^:]+:latest`, input.content)

  result := {
    "rule": "block-latest-tag",
    "category": "quality",
    "priority": 80,
    "severity": "block",
    "message": "Using :latest tag is not allowed. Specify explicit version tags.",
    "description": "Prevent :latest for reproducibility",
  }
}

# Non-blocking warnings
warnings contains result if {
  input_type == "dockerfile"
  not regex.match(`HEALTHCHECK`, input.content)

  result := {
    "rule": "suggest-healthcheck",
    "category": "quality",
    "priority": 70,
    "severity": "warn",
    "message": "Consider adding HEALTHCHECK instruction for container monitoring",
    "description": "HEALTHCHECK improves container lifecycle management",
  }
}

# Policy decision
default allow := false
allow if count(violations) == 0

# Result structure
result := {
  "allow": allow,
  "violations": violations,
  "warnings": warnings,
  "suggestions": [],
  "summary": {
    "total_violations": count(violations),
    "total_warnings": count(warnings),
    "total_suggestions": 0,
  },
}
```

**Priority Levels:**
- **90-100**: Security rules (highest priority)
- **70-89**: Quality rules
- **50-69**: Performance rules
- **30-49**: Compliance rules

**Using Policies:**

```bash
# List discovered policies
npx containerization-assist-mcp list-policies

# List policies and show merged result
npx containerization-assist-mcp list-policies --show-merged

# Validate Dockerfile with policies (automatic discovery)
npx containerization-assist-mcp fix-dockerfile --path ./Dockerfile
```

**Creating Custom Policies:**

See [Policy Customization Guide](docs/guides/policy-getting-started.md) and existing policies in `policies/` for examples.

**Testing Policies:**

```bash
# Validate policy syntax
opa check .containerization-assist/policy/my-policy.rego

# Run policy tests
opa test .containerization-assist/policy/

# Test with MCP Inspector
npx @modelcontextprotocol/inspector containerization-assist-mcp start
```

### MCP Inspector (Testing)

```bash
npx @modelcontextprotocol/inspector containerization-assist-mcp start
```

## Troubleshooting

### Docker Connection Issues

```bash
# Check Docker is running
docker ps

# Check socket permissions (Linux/Mac)
ls -la /var/run/docker.sock

# For Windows, ensure Docker Desktop is running
```

### MCP Connection Issues

```bash
# Test with MCP Inspector
npx @modelcontextprotocol/inspector containerization-assist-mcp start

# Check logs with debug level
npx -y containerization-assist-mcp start --log-level debug
```

### Kubernetes Connection Issues

The server performs fast-fail validation when Kubernetes tools are used. If you encounter Kubernetes errors:

**Kubeconfig Not Found**
```bash
# Check if kubeconfig exists
ls -la ~/.kube/config

# Verify kubectl can connect
kubectl cluster-info

# If using cloud providers, update kubeconfig:
# AWS EKS
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Google GKE
gcloud container clusters get-credentials <cluster-name> --zone <zone>

# Azure AKS
az aks get-credentials --resource-group <rg> --name <cluster-name>
```

**Connection Timeout or Refused**
```bash
# Verify cluster is running
kubectl get nodes

# Check API server address
kubectl config view

# Test connectivity to API server
kubectl cluster-info dump

# Verify firewall rules allow connection to API server port (typically 6443)
```

**Authentication or Authorization Errors**
```bash
# Check current context and user
kubectl config current-context
kubectl config view --minify

# Test permissions
kubectl auth can-i create deployments --namespace default
kubectl auth can-i create services --namespace default

# If using cloud providers, refresh credentials:
# AWS EKS: re-run update-kubeconfig
# GKE: run gcloud auth login
# AKS: run az login
```

**Invalid or Missing Context**
```bash
# List available contexts
kubectl config get-contexts

# Set a context
kubectl config use-context <context-name>

# View current configuration
kubectl config view
```

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Support

See [SUPPORT.md](SUPPORT.md) for information on how to get help with this project.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must [follow Microsoft’s Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.




```
# ARO MCP Server

A Model Context Protocol (MCP) server for Azure Red Hat OpenShift (ARO) cluster management. This server enables AI assistants like GitHub Copilot to query, manage, and troubleshoot ARO clusters directly from VS Code.

## What is this?

This MCP server exposes ARO cluster operations as tools that AI agents can invoke. When connected to VS Code Copilot (Agent mode), you can ask natural language questions like:

- *"List my ARO clusters in subscription xyz"*
- *"Get details of aro-mcp-cluster in resource group aro-mcp-centralus"*
- *"What's the provisioning state of my ARO cluster?"*

Copilot will automatically call the `aro_cluster_get` tool to retrieve live data from your Azure subscription.

## Available Tools

| Tool | Description |
|---|---|
| `aro_cluster_get` | List all ARO clusters in a subscription, or get details of a specific cluster (profiles, networking, API server, worker nodes, provisioning state) |
| `aro_cluster_diagnose` | AI-powered diagnosis of ARO cluster issues using Azure OpenAI — sends cluster data and your question to GPT-4o for expert analysis |
| `aro_cluster_summarize` | AI-powered cluster summary — generates a health assessment, configuration overview, and recommendations using Azure OpenAI |

## Prerequisites

- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) or later
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az login` authenticated)
- [VS Code](https://code.visualstudio.com/) with [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat) extension
- [Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/) resource with a GPT-4o deployment (for diagnose/summarize tools)
- An Azure subscription with the `Microsoft.RedHatOpenShift` resource provider registered
- [kubectl](https://kubernetes.io/docs/tasks/tools/) or [oc CLI](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/) for cluster operations
- The pre-built `azmcp.exe` binary (see [Setup](#setup) below)

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/sschinna/aro-mcp-server.git
cd aro-mcp-server
```

### 2. Install the Azure MCP Server binary

Download or build the `azmcp` binary and place it in `~/.aro-mcp/`:

```powershell
# Option A: Install from the official Azure MCP NuGet tool
dotnet tool install --global Azure.Mcp

# Option B: Use a pre-built binary
# Copy azmcp.exe to ~/.aro-mcp/ (Windows) or ~/.aro-mcp/ (Linux/macOS)
mkdir -p ~/.aro-mcp
cp /path/to/azmcp.exe ~/.aro-mcp/
```

### 3. Authenticate with Azure

On Windows, the Azure CLI may fail with AADSTS or token cache errors on first use. Run this **once** to fix:

```bash
az account clear
az config set core.enable_broker_on_windows=false
az login
az account set --subscription <YOUR_SUBSCRIPTION_ID>
```

> **Note:** The `az account clear` and `az config set` steps are only needed once. After that, `az login` works reliably.

### 4. Configure VS Code MCP Server

The repo includes `.vscode/mcp.json` which auto-registers the server when you open the workspace. No manual setup needed.

To add it to **another workspace** or **globally**, add this to your VS Code `settings.json`:

```json
{
  "mcp": {
    "servers": {
      "aro-mcp-server": {
        "type": "stdio",
        "command": "dotnet",
        "args": [
          "run", "--project",
          "/path/to/aro-mcp-server/tools/Azure.Mcp.Tools.Aro/src/Azure.Mcp.Tools.Aro.csproj",
          "--", "server", "start", "--transport", "stdio"
        ]
      }
    }
  }
}
```

### 5. Authenticate to your ARO cluster

Run the login script — it will ask how you want to connect:

```powershell
.\scripts\aro-login.ps1
```

```
ARO Cluster Login
  How would you like to connect?

  [S] Subscription lookup  — provide subscription ID, resource group, and cluster name
  [A] API Server direct    — provide the ARO API server URL

Choose login mode [S/A] (default: S):
```

#### Option A: Direct API Server Login (no Azure subscription needed)

If you already have the ARO API server URL and credentials (e.g., `kubeadmin` username/password), choose `[A]` or use the `-Direct` flag:

```powershell
# Interactive — prompts for API server URL, username, and password (password is hidden)
.\scripts\aro-login.ps1 -Direct
```

```powershell
# With parameters (password is always prompted securely, never passed as argument)
.\scripts\aro-login.ps1 -Direct `
  -ApiServer "https://api.mycluster.eastus.aroapp.io:6443" `
  -Username "kubeadmin"
```

```powershell
# With environment variables (password still prompted securely)
$env:ARO_API_SERVER = "https://api.mycluster.eastus.aroapp.io:6443"
$env:ARO_USERNAME = "kubeadmin"
.\scripts\aro-login.ps1 -Direct
```

> **Security:** The password is always prompted using `Read-Host -AsSecureString` and is never displayed, logged, or stored in shell history. It is cleared from memory immediately after login.

**Requirements:** Only the `oc` CLI is needed. No Azure CLI, no Azure subscription.

#### Option B: Subscription Lookup (automatic credential retrieval)

Choose `[S]` at the prompt, or provide parameters directly. This mode uses Azure CLI to automatically retrieve kubeadmin credentials and exchange them for an OAuth token — no need to know the password.

**Interactive mode (prompts for all values):**
```powershell
.\scripts\aro-login.ps1
```

**With parameters:**
```powershell
.\scripts\aro-login.ps1 `
  -SubscriptionId "<YOUR_SUBSCRIPTION_ID>" `
  -ResourceGroup "<YOUR_RESOURCE_GROUP>" `
  -ClusterName "<YOUR_CLUSTER_NAME>"
```

**With environment variables:**
```powershell
$env:AZURE_SUBSCRIPTION_ID = "<YOUR_SUBSCRIPTION_ID>"
$env:ARO_RESOURCE_GROUP = "<YOUR_RESOURCE_GROUP>"
$env:ARO_CLUSTER_NAME = "<YOUR_CLUSTER_NAME>"
.\scripts\aro-login.ps1
```

What the Azure mode script does:
1. Verifies Azure CLI login (auto-triggers `az login` if expired)
2. Retrieves cluster endpoint from Azure
3. Fetches kubeadmin credentials (never displayed)
4. Exchanges credentials for an OAuth token (never displayed)
5. Configures `~/.kube/config` with the token
6. Clears all sensitive data from memory

**Requirements:** Azure CLI (`az`), `kubectl`, an Azure subscription with access to the ARO cluster.

### Azure OpenAI Configuration (for AI Tools)

The `aro_cluster_diagnose` and `aro_cluster_summarize` tools require Azure OpenAI. Set these environment variables:

```powershell
$env:AZURE_OPENAI_ENDPOINT = "https://your-resource.openai.azure.com/"
$env:AZURE_OPENAI_DEPLOYMENT = "gpt-4o"  # Your model deployment name
```

Authentication uses `DefaultAzureCredential` (Azure CLI, Managed Identity, etc.). Ensure your identity has the **Cognitive Services OpenAI User** role on the Azure OpenAI resource.

#### After login (either mode)

```bash
kubectl get nodes
kubectl get clusteroperators
kubectl top nodes
oc get pods -A
oc get clusterversion
```

### 6. Use with Copilot

1. Open VS Code and switch Copilot Chat to **Agent mode**
2. Click the **Tools icon** (wrench) to verify `aro_cluster_get` is listed
3. Ask a question about your ARO clusters

## Teammate Onboarding (Quick Start)

If a teammate clones this repo, here's the minimal checklist to get everything working:

### Step-by-step

1. **Install .NET 10 SDK**
   ```bash
   # Verify: dotnet --version should show 10.x
   ```

2. **Install Azure CLI and authenticate**
   ```bash
   az account clear                              # one-time fix for Windows token cache
   az config set core.enable_broker_on_windows=false  # one-time fix for Windows
   az login
   az account set --subscription <SUBSCRIPTION_ID>
   ```

3. **Build the MCP server plugin**
   ```bash
   cd aro-mcp-server
   dotnet build tools/Azure.Mcp.Tools.Aro/src/Azure.Mcp.Tools.Aro.csproj
   ```

4. **Install the Azure MCP runtime** — Place `azmcp.exe` in `~/.aro-mcp/`:
   ```powershell
   # Option A: Install via .NET global tool
   dotnet tool install --global Azure.Mcp

   # Option B: Copy a pre-built binary
   New-Item -ItemType Directory -Force "$env:USERPROFILE\.aro-mcp"
   Copy-Item /path/to/azmcp.exe "$env:USERPROFILE\.aro-mcp\"
   ```

5. **Open the workspace in VS Code** — `.vscode/mcp.json` auto-registers the server. No manual config needed.

6. **Login to your ARO cluster**
   ```powershell
   .\scripts\aro-login.ps1
   ```

7. **(Optional) Configure Azure OpenAI for AI tools** — Only needed for `aro_cluster_diagnose` and `aro_cluster_summarize`:
   ```powershell
   $env:AZURE_OPENAI_ENDPOINT = "https://<your-resource>.openai.azure.com/"
   $env:AZURE_OPENAI_DEPLOYMENT = "gpt-4o"
   ```
   Your identity also needs the **Cognitive Services OpenAI User** role on the Azure OpenAI resource.

### What works out of the box vs. what doesn't

| Component | Portable? | Notes |
|---|---|---|
| Source code & build | ✅ Yes | Standard .NET project, no hardcoded paths |
| `.vscode/mcp.json` | ✅ Yes | Uses `azmcp` from PATH or `~/.aro-mcp/` (via `$(USERPROFILE)`) |
| Azure authentication | ✅ Yes | `DefaultAzureCredential` — works with any user's `az login` |
| `azmcp.exe` runtime | ⚠️ Manual | Must be installed per-user (see step 4) |
| ARO cluster access | ⚠️ Manual | Each user needs `az login` + RBAC on the subscription |
| Azure OpenAI (AI tools) | ⚠️ Optional | Env vars + role assignment needed (see step 7) |
| `obj/` build artifacts | ✅ Gitignored | User-specific NuGet paths in `obj/` are not committed |

## Usage Examples

### With Copilot (Agent Mode)

**List all clusters in a subscription:**
```
User: List my ARO clusters
```

**Get specific cluster details:**
```
User: Get details of my-aro-cluster in resource group my-aro-rg
```

**Check cluster health:**
```
User: What is the provisioning state and worker count of my ARO cluster?
```

**Node and operator diagnostics (via kubectl/oc):**
```
User: Check the ARO cluster node health and CPU utilization
User: Share the cluster operators status
User: Check DNS health on my ARO cluster
```

### With kubectl / oc CLI

After running `.\scripts\aro-login.ps1` (or `.\scripts\aro-login.ps1 -Direct`):

```bash
# Node status
kubectl get nodes -o wide

# CPU and memory utilization
kubectl top nodes

# Cluster operators
oc get clusteroperators

# DNS health
oc get dns.operator/default -o yaml
oc get pods -n openshift-dns

# Pod status across all namespaces
oc get pods -A --field-selector status.phase!=Running

# Cluster version
oc get clusterversion
```

### Direct oc login (without the script)

> **Security:** Never pass passwords on the command line (e.g., `oc login -p <password>`). Passwords in command-line arguments are visible in process lists, shell history, and terminal logs.

Use `oc login` interactively instead — it will prompt for the password securely:

```bash
oc login https://api.mycluster.eastus.aroapp.io:6443 -u kubeadmin --insecure-skip-tls-verify
# Password: (enter securely at prompt — not displayed)
```

For automated/non-interactive flows, prefer the login script which retrieves credentials via Azure CLI and exchanges them for an OAuth token without ever exposing them:

```powershell
.\scripts\aro-login.ps1
```

The tool returns cluster metadata including:
- Cluster profile (domain, version, FIPS status)
- API server profile (URL, IP, visibility)
- Console URL
- Network profile (pod CIDR, service CIDR, outbound type)
- Master profile (VM size, subnet, encryption)
- Worker profiles (count, VM size, disk size, zones)
- Ingress profiles
- Provisioning state
- Tags

## Troubleshooting

### `az login` fails with AADSTS errors or token cache issues

If you see errors like `Can't find token from MSAL cache`, `AADSTS50076`, or `AADSTS5000224`:

```bash
az account clear
az config set core.enable_broker_on_windows=false
az login
```

This disables the Windows WAM broker and switches to browser-based authentication.

### MCP server fails to start in VS Code

1. Open the Command Palette (`Ctrl+Shift+P`) → **MCP: List Servers** → find `aro-mcp-server` → **Restart**
2. Ensure you are authenticated: `az account show`
3. Verify the `Microsoft.RedHatOpenShift` resource provider is registered:
   ```bash
   az provider show --namespace Microsoft.RedHatOpenShift --query "registrationState" -o tsv
   ```
4. Check the Output panel in VS Code (select "MCP" from the dropdown) for error details

### `kubectl` / `oc` commands fail with authentication errors

Your cluster token may have expired (tokens last 24 hours). Re-run the login script:
```powershell
.\scripts\aro-login.ps1
```

### Installing the `oc` CLI

Download from the [OpenShift mirror](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/):

```powershell
# Windows (PowerShell)
curl.exe -sLo "$env:TEMP\oc.zip" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-windows.zip"
Expand-Archive "$env:TEMP\oc.zip" "$env:TEMP\oc-install" -Force
Copy-Item "$env:TEMP\oc-install\oc.exe" "$env:USERPROFILE\.aro-mcp\oc.exe"
# Add ~/.aro-mcp to your PATH
```

## Tool Parameters

### `aro_cluster_get`

| Parameter | Required | Description |
|---|---|---|
| `--subscription` | Yes | Azure subscription ID |
| `--resource-group` | No | Resource group name (required if `--cluster` is specified) |
| `--cluster` | No | ARO cluster name. If omitted, lists all clusters in the subscription |

## ARO Cluster Deployment (Bicep)

The `aro-deploy/` directory contains a Bicep template for creating an ARO cluster with **managed identity** (no service principal needed). This avoids credential lifetime policy issues common in enterprise tenants.

### Prerequisites for Deployment

1. **Register the ARO resource provider** (one-time per subscription):
   ```bash
   az provider register --namespace Microsoft.RedHatOpenShift --wait
   az provider show --namespace Microsoft.RedHatOpenShift --query "registrationState" -o tsv
   # Should output: Registered
   ```

2. **Check available ARO versions** in your target region:
   ```bash
   az aro get-versions --location centralus -o table
   ```

3. **Verify VM SKU availability** (some subscriptions restrict certain SKUs):
   ```bash
   az vm list-skus --location centralus --resource-type virtualMachines \
     --query "[?name=='Standard_D8s_v3'].restrictions" -o table
   ```
   If restricted, try a different region or VM size.

4. **Get the ARO Resource Provider service principal Object ID**:
   ```bash
   az ad sp list --display-name "Azure Red Hat OpenShift RP" --query '[0].id' -o tsv
   ```

### Deploy an ARO Cluster

#### Cluster Creation Demo Video

https://github.com/sschinna/aro-mcp-server/releases/download/demo-videos/aro_cluster_creation_compressed.mp4

```bash
# Set variables
LOCATION=centralus
RESOURCEGROUP=aro-rg
CLUSTER=my-aro-cluster
VERSION=4.18.34    # Use a version from az aro get-versions
ARO_RP_SP_OBJECT_ID=$(az ad sp list --display-name "Azure Red Hat OpenShift RP" --query '[0].id' -o tsv)

# Create resource group
az group create --name $RESOURCEGROUP --location $LOCATION

# Deploy ARO cluster (~35-45 minutes)
az deployment group create \
  --name aroDeployment \
  --resource-group $RESOURCEGROUP \
  --template-file aro-deploy/azuredeploy.bicep \
  --parameters location=$LOCATION \
  --parameters version=$VERSION \
  --parameters clusterName=$CLUSTER \
  --parameters rpObjectId=$ARO_RP_SP_OBJECT_ID
```

> **Note:** Deployment takes approximately 35-45 minutes. If a role assignment fails due to identity propagation delays, simply re-run the deployment — it is idempotent.

### What the Bicep Template Creates

| Resource | Count | Description |
|---|---|---|
| Virtual Network | 1 | With master and worker subnets |
| User-Assigned Managed Identities | 9 | Cluster identity + 8 operator identities |
| Role Assignments | 20 | Permissions for all operator identities |
| ARO Cluster | 1 | With `platformWorkloadIdentityProfile` and managed identity |

Default configuration:
- **Master nodes:** 3x `Standard_D8s_v3`
- **Worker nodes:** 3x `Standard_D4s_v3` (128 GB disk)
- **Network:** Pod CIDR `10.128.0.0/14`, Service CIDR `172.30.0.0/16`
- **Visibility:** Public API server and ingress

### Customizable Parameters

| Parameter | Default | Description |
|---|---|---|
| `location` | Resource group location | Azure region |
| `version` | *(required)* | OpenShift version (e.g., `4.18.34`) |
| `clusterName` | *(required)* | Unique cluster name |
| `rpObjectId` | *(required)* | ARO RP service principal Object ID |
| `masterVmSize` | `Standard_D8s_v3` | Master node VM size |
| `workerVmSize` | `Standard_D4s_v3` | Worker node VM size |
| `workerVmDiskSize` | `128` | Worker disk size in GB |
| `apiServerVisibility` | `Public` | `Public` or `Private` |
| `ingressVisibility` | `Public` | `Public` or `Private` |
| `fips` | `Disabled` | FIPS-validated crypto modules |
| `pullSecret` | *(empty)* | Red Hat pull secret from cloud.redhat.com |

### Post-Deployment

```bash
# Verify cluster is running
az aro show --name $CLUSTER --resource-group $RESOURCEGROUP \
  --query "{state:provisioningState, console:consoleProfile.url, api:apiserverProfile.url}" -o table

# Access the OpenShift console
az aro show --name $CLUSTER --resource-group $RESOURCEGROUP --query consoleProfile.url -o tsv

# Login securely using the login script (credentials never exposed)
# The script retrieves credentials via Azure CLI and exchanges them for an OAuth token
pwsh ./scripts/aro-login.ps1 -SubscriptionId "$SUBSCRIPTION_ID" -ResourceGroup "$RESOURCEGROUP" -ClusterName "$CLUSTER"

# Or login interactively (oc prompts for password securely)
API_URL=$(az aro show --name $CLUSTER --resource-group $RESOURCEGROUP --query apiserverProfile.url -o tsv)
oc login $API_URL -u kubeadmin --insecure-skip-tls-verify
# Password: (enter at secure prompt)

# IMPORTANT: Never use 'az aro list-credentials' output directly on the command line.
# Credentials in command-line arguments are visible in process lists and shell history.
```

### Cleanup

```bash
# Delete the ARO cluster and all resources
az aro delete --name $CLUSTER --resource-group $RESOURCEGROUP --yes
az group delete --name $RESOURCEGROUP --yes --no-wait
```

## Project Structure

```
aro-mcp-server/
├── .vscode/
│   └── mcp.json                          # VS Code MCP server auto-config
├── scripts/
│   └── aro-login.ps1                     # Secure ARO cluster authentication
├── aro-deploy/
│   └── azuredeploy.bicep                 # ARO cluster Bicep template (managed identity)
├── Directory.Build.props                 # Shared build settings (net10.0)
├── Directory.Packages.props              # Centralized NuGet package versions
├── aro-mcp-server.sln                    # Solution file
└── tools/
    └── Azure.Mcp.Tools.Aro/
        ├── src/
        │   ├── AroSetup.cs               # Tool area registration (IAreaSetup)
        │   ├── Commands/
        │   │   ├── AroJsonContext.cs      # AOT-compatible JSON serialization
        │   │   ├── BaseAroCommand.cs      # Base command class
        │   │   └── Cluster/
        │   │       └── ClusterGetCommand.cs  # aro_cluster_get implementation
        │   ├── Models/
        │   │   └── Cluster.cs            # ARO cluster model
        │   ├── Options/
        │   │   ├── AroOptionDefinitions.cs
        │   │   ├── BaseAroOptions.cs
        │   │   └── Cluster/
        │   │       └── ClusterGetOptions.cs
        │   └── Services/
        │       ├── AroService.cs         # Azure ARM client for ARO
        │       └── IAroService.cs
        └── tests/
            └── Azure.Mcp.Tools.Aro.UnitTests/
                └── Cluster/
                    └── ClusterGetCommandTests.cs
```

## Sharing with Your Team

| Team size | Recommended approach |
|---|---|
| 2-5 | Clone this repo, each person runs locally |
| 5-20 | Publish a self-contained binary: `dotnet publish -c Release -r win-x64 --self-contained` |
| 20+ | Host as HTTP/SSE server for centralized access |

### Build from Source

The project references core MCP libraries via DLL from the `azmcp` install directory (`~/.aro-mcp/`). To build:

```bash
git clone https://github.com/sschinna/aro-mcp-server.git
cd aro-mcp-server
dotnet build
```

To build with a custom `azmcp` location:
```bash
dotnet build /p:AzmcpDir=/path/to/azmcp/directory
```

## License

MIT