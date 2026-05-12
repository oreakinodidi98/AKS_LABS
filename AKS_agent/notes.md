# Agent Skills for AKS

> Bring production-grade AKS guidance directly into any compatible AI agent — using the same commands, checklists, and diagnostic approaches that AKS engineers use today.

---

## Table of Contents

- [Agent Skills for AKS](#agent-skills-for-aks)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [What is an Agent Skill](#what-is-an-agent-skill)
  - [Available Skills](#available-skills)
    - [Best Practices](#best-practices)
    - [Troubleshooting](#troubleshooting)
  - [AI-Powered Capabilities for AKS](#ai-powered-capabilities-for-aks)
  - [Getting Started](#getting-started)
    - [Option 1: GitHub Copilot for Azure plugin](#option-1-github-copilot-for-azure-plugin)
      - [VS Code](#vs-code)
      - [Claude or Copilot CLI](#claude-or-copilot-cli)
    - [Option 2: Install skills directly](#option-2-install-skills-directly)
  - [References](#references)

---

## Overview

AI agents have a good baseline of Kubernetes and AKS knowledge, but that knowledge is only as current as their training data and varies across models. AKS skills close that gap by giving agents prescriptive, up-to-date guidance on the tools and processes the AKS engineering team uses today — covering cluster creation, operations, and issue resolution.

---

## What is an Agent Skill

Agent Skills are modular packages that give agents specialized capabilities and domain expertise, loading only the context needed at the time.

- **Open standard** pioneered by Anthropic for enhancing AI agents with domain-specific expertise in a token-efficient way
- **Install once** — any compatible agent (GitHub Copilot, Claude, Gemini, etc.) picks it up automatically, loading only what's relevant to your prompt

---

## Available Skills

### Best Practices

Guides agents through cluster configuration recommendations across networking, upgrade strategy, security, reliability, and scale. The guidance reflects what the AKS engineering team recommends for production clusters, including specific defaults and critical decisions that apply to AKS.

### Troubleshooting

Covers the most common incident scenarios: node health failures and networking issues. Includes the exact CLI commands and diagnostic sequences AKS engineers use internally when working on customer incidents.

> **Permission-gated:** The skill only suggests and executes commands that your current credentials allow, so there is no risk of unintentional changes.

---

## AI-Powered Capabilities for AKS

AKS offers three complementary AI-powered experiences. Understanding each one helps you choose the right combination for your workflow.

| Capability | Role | Requires cluster | Best for |
|---|---|---|---|
| **AKS skills** | Knowledge | No | Cluster configuration, best practices, and troubleshooting guidance |
| **AKS MCP server** | Tools | Yes | Live diagnostics, cluster state, and Azure/Kubernetes API access |
| **Agentic CLI for AKS** | End-to-end experience | Yes | AI-powered cluster operations without assembling individual tools |

- **AKS skills** enhance the base knowledge of any compatible agent. They tell the agent *what* to do but don't connect to your cluster.
- **AKS MCP server** pairs with skills to give the agent the ability to *act* — securely accessing cluster details, running scoped diagnostic commands, and calling Kubernetes and Azure APIs. Without it, agents fall back to direct CLI commands, which lack the structured, permission-aware interface the MCP server provides.
- **Agentic CLI for AKS** (`az aks agent`) is a purpose-built terminal experience that combines skills and tooling in one place. The right choice when you want AI-powered AKS operations without assembling the pieces yourself. Built-in support for all AKS skills is in progress.

---

## Getting Started

AKS skills are available through the **GitHub Copilot for Azure** extension (recommended) or can be installed directly.

### Option 1: GitHub Copilot for Azure plugin

The plugin bundles AKS skills alongside 20+ skills across cost optimization, other Azure resources, and deployment workflows. It is available in VS Code, Claude, and Copilot CLI.

#### VS Code

1. Open the Extensions marketplace (`Ctrl+Shift+X` / `Cmd+Shift+X`), search for **GitHub Copilot for Azure**, and select **Install**
2. Open GitHub Copilot Chat (`Ctrl+Alt+I` / `Cmd+Alt+I`)
3. Run an AKS-related prompt such as _"What's the recommended upgrade strategy for my AKS cluster?"_ — the AKS skill loads automatically

> **Tip:** If skills don't activate, open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run **GitHub Copilot for Azure: Refresh Skills**

#### Claude or Copilot CLI

1. Add the marketplace: `/plugin marketplace add microsoft/azure-skills`
2. Install the plugin: `/plugin install azure@azure-skills`
3. Verify the AKS skill is loaded: `/skills` (look for `azure-kubernetes`)
4. Run an AKS-related prompt — the skill invokes automatically

> **Tip:** To update the plugin at any time, run `/plugin update azure@azure-skills`

---

### Option 2: Install skills directly

Use `npx` to install specific skills directly from the repo:

```bash
npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-kubernetes
npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-diagnostics
```

Alternatively, download the skill file from the reference links below and place it in your skills directory (e.g. `~/.copilot/skills` or `~/.claude/skills`).

---

## References

- [Agent Skills specification](https://learn.microsoft.com/en-gb/agent-framework/agents/skills?pivots=programming-language-csharp)
- [AKS Agent Skills blog post](https://blog.aks.azure.com/2026/04/08/agent-skills-for-aks)
- [AKS Best Practices skill (SKILL.md)](https://github.com/microsoft/GitHub-Copilot-for-Azure/blob/main/plugin/skills/azure-kubernetes/SKILL.md)
- [AKS Troubleshooting skill](https://github.com/microsoft/GitHub-Copilot-for-Azure/tree/main/plugin/skills/azure-diagnostics/aks-troubleshooting)