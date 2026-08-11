# Microsoft Foundry Chatbot on AKS Automatic

In this demo I walk through deploying an AKS Automatic cluster, provisioning a Microsoft Foundry resource with a chat model, and running an MCP server that connects directly to that model deployment.

## AKS Automatic

AKS Automatic takes care of node provisioning, autoscaling, and workload identity for you — there's very little cluster management involved. The key security piece here is that instead of storing a model API key in Kubernetes, each pod exchanges its Kubernetes service account token for a Microsoft Entra token at runtime. That means no secrets sitting in your cluster config. This same pattern — workload identity, container deployments, autoscaling — also works great for running MCP servers and AI agents that talk to Microsoft Foundry directly from AKS.

## Prerequisites

Before running this, make sure you have:

- Azure CLI logged in with permissions to create AKS clusters, ACR registries, Cognitive Services resources, managed identities, federated credentials, and role assignments
- A version of the Azure CLI that supports `az aks create --sku automatic`
- `kubectl` and `yq` installed locally

A few important things to know about the MCP server in this demo:

- It exposes a single tool that forwards a prompt to the deployed Microsoft Foundry model and returns the response
- It's built with the MCP Python SDK using `FastMCP` with streamable HTTP transport — so any MCP-compatible client or agent framework can call it over the network
- **The MCP endpoint has no authentication or authorization of its own** — the tool sends whatever prompt it receives straight to the Foundry model
- The service is exposed to the public internet via a LoadBalancer
- For production use, add ingress rules with authentication, TLS, rate limiting, and input validation before using this pattern

## Calling the MCP Server

Once the service is deployed, wait for the `EXTERNAL-IP` to be populated. The streamable HTTP endpoint will be available at:

```
http://<EXTERNAL-IP>/mcp
```

I'm using MCP Inspector as the client. Start it with:

```bash
npx @modelcontextprotocol/inspector
```

Select the streamable HTTP transport, connect to the endpoint, and call the tool with a prompt argument.