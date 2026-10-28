# Master Your Momentum: Building Private Intelligence for AKS/ARO Operations

> Leading organizations aren't just looking for better clusters — they're building the brainpower to operate them autonomously.


---

## Section 1: The Case for Agentic Ops

---

### Slide 1: The Modern Kubernetes Crisis

**Hook:** As clusters grow in complexity (multi-cloud, hybrid, ARO), the "cognitive load" on platform engineers is becoming unsustainable.

**Key Points:**

- **The Scale Problem** — Enterprise Kubernetes footprints have exploded: multi-region, multi-cloud, hybrid (AKS + ARO), hundreds of namespaces, thousands of workloads. The blast radius of a single misconfiguration is enormous.
- **The Tooling Paradox** — We spent a decade perfecting CI/CD pipelines, GitOps, and infrastructure-as-code for *deployment*. But when something breaks at 2 AM, engineers are still SSH-ing into nodes, tailing logs, and running `kubectl describe` in a loop — the same workflow from 2014.
- **The Cognitive Load Tax** — Platform engineers today must hold mental models of networking (CNI, service mesh, DNS), security (RBAC, Pod Security, network policies), storage, scaling, upgrades, and compliance — simultaneously. This is not a tooling gap; it's a *knowledge throughput* gap.
- **The Attrition Risk** — When the entire operational playbook lives in one or two senior engineers' heads, every departure is a production risk event.

**Visual Idea:** Side-by-side graphic — *2014: 1 cluster, 10 YAMLs, 1 CLI* vs. *2026: 15 clusters, 2,000+ YAMLs, still the same CLI* — with the engineer's "cognitive load meter" redlining.

---

### Slide 2: Beyond "Copilot" — The Agentic Leap

**Concept:** There is a critical difference between *chatting with docs* and *agents with context*.

**Key Points:**

- **Renting vs. Owning AI** — Most teams today are "renting" AI: they paste an error into ChatGPT, get a generic answer, and manually adapt it to their environment. Leaders are "owning" AI: they give agents *direct, authenticated access* to live cluster state, policies, and history so the agent reasons over *their* reality, not the internet's.
- **The MCP Shift (Model Context Protocol)** — MCP is the bridge. It lets an AI agent call into AKS/ARO APIs, read node conditions, inspect pod events, pull metrics — all in real-time. The agent doesn't *guess* what's wrong; it *observes* what's wrong.
- **From Search to Action** — "AI-assisted search" = you ask a question, you get a doc link. "AI-native action" = the agent detects a crashlooping pod, correlates it with a recent deployment, checks resource quotas, and drafts a remediation — before you even open a terminal.
- **Context is the Moat** — The real competitive advantage isn't the LLM (everyone has access to the same models). It's the *context layer* you build: your runbooks, your cluster topology, your incident history, your compliance constraints. That context turns a generic assistant into a domain expert.

**Key Phrase:** *Moving from AI-assisted search to AI-native action.*

---

### Slide 3: The Architecture of Intelligence

**Concept:** You aren't deploying a new CLI — you're embedding expert knowledge into the platform itself.

**Key Points:**

- **The Flow** — `User → Agentic CLI / Copilot Chat → MCP Server → AKS/ARO API → Cluster State`. The MCP Server acts as the "nervous system," translating natural-language intent into authenticated API calls and returning structured, contextual results back to the agent.
- **Three Layers of Intelligence:**
  1. **Skills Layer** — Curated, domain-specific guidance (best practices, troubleshooting playbooks, Day-0 checklists) that activate only when relevant. These are *not* static docs — they are structured prompts that shape how the agent reasons.
  2. **Context Layer (MCP)** — Live, read-only access to cluster state: node health, pod events, resource utilization, network policies, RBAC bindings. This is what makes the agent's answers *specific to your environment*.
  3. **Action Layer** — The agent can propose (and with approval, execute) remediations: scaling a deployment, cordoning a node, applying a network policy. Every action is permission-aware and audit-logged.
- **Why This Matters** — This architecture means knowledge compounds. Every incident, every runbook, every policy decision can be encoded into the skills and context layers. New engineers get the benefit of the entire team's operational history from day one.
- **ARO Parity** — The same architecture works across AKS and Azure Red Hat OpenShift (ARO). The MCP Server abstracts the API differences, so your operational intelligence is portable.

**Visual Idea:** A layered architecture diagram — User at the top, Agentic CLI / Copilot in the middle, MCP Server as a hub connecting to AKS API, ARO API, Azure Monitor, and a Skills Repository. Arrows show the bidirectional flow: intent flows down, context flows up.

---

*This section sets the stage: you aren't showing a new CLI — you're showing a new way to embed expert knowledge into the platform itself.*

---
---

## Section 2: The Blueprint — Bridging the Skills Gap with AI-Native Workflows (AKS Skills)

> *"Don't train your people to use better tools. Train your tools to carry your people's expertise."*

---

### Slide 4: The Skills Gap Is the Real Bottleneck

**Hook:** The hardest thing to scale in Kubernetes isn't pods — it's people.

**Key Points:**

- **Knowledge Doesn't Scale Like Compute** — You can auto-scale a node pool in seconds. You cannot auto-scale a senior platform engineer's understanding of CNI overlay vs. kubenet trade-offs, or when to use PodDisruptionBudgets vs. surge upgrades. That knowledge takes years to build and minutes to lose when someone leaves.
- **The Training Treadmill** — Kubernetes releases every four months. AKS adds features every sprint. The official docs are 5,000+ pages. Even dedicated teams can't keep up. The result: engineers default to "what worked last time" instead of "what's recommended now."
- **The Consistency Problem** — Ask three engineers how to configure networking for a new AKS cluster and you'll get three different answers. Without a single source of prescriptive truth, every cluster becomes a snowflake.
- **The Real Cost** — Redhat research from 2023, 45% of respondents experienced security incidents or issues related to containers and/or Kubernetes due to misconfigurations, not infrastructure. The skills gap isn't an HR problem — it's an availability problem.

**Slogan:** *The bottleneck isn't your cluster. It's the space between the cluster and your team's knowledge.*

**Visual Idea:** An iceberg graphic — above the waterline: "Deployment Automation (CI/CD, GitOps, IaC) — Solved." Below the waterline (much larger): "Operational Knowledge (Best Practices, Troubleshooting, Day-2 Decisions) — Still Manual."

**Speaker Notes:**
> This is where you anchor the audience emotionally. Every platform team in the room has felt this. Pause after the Gartner stat — let it land. The goal is to make the audience realize the problem isn't tooling, it's *knowledge distribution*. That reframes everything that follows.

---

### Slide 5: What Is an Agent Skill? (The Building Block)

**Hook:** An agent skill is a modular package of expert knowledge that loads into any AI agent — on demand, at the moment of need.

**Key Points:**

- **Not a Doc, Not a Chatbot** — A skill is *structured reasoning context*. It doesn't just tell the agent "here's a link to the docs." It shapes *how the agent thinks* about a problem: what questions to ask, what commands to run, what order to investigate, what guardrails to enforce.
- **Open Standard** — Pioneered by Anthropic for token-efficient domain expertise. This isn't a proprietary lock-in — it works across GitHub Copilot, Claude, Gemini, and any MCP-compatible agent. Install once, benefit everywhere.
- **Lazy-Loading Intelligence** — Skills activate only when relevant. Ask about Python? The AKS skill stays dormant. Ask about node health? It loads automatically with the exact diagnostic sequence AKS engineers use internally. This keeps agent context windows lean and responses precise.
- **Composable** — Skills stack. AKS best practices + AKS troubleshooting + your custom governance skill = a compound expert that no single human could match in breadth and consistency.

**Slogan:** *Install expertise. Not just extensions.*

**Visual Idea:** A "plug-in brain" graphic — a stylized AI agent head with modular skill blocks slotting in: "AKS Best Practices," "AKS Troubleshooting," "Custom: Governance," "Custom: Incident Runbooks." Each block glows when activated by a relevant prompt.

**Speaker Notes:**
> Emphasize the *open standard* angle — this resonates with platform teams who are skeptical of vendor lock-in. The key differentiator vs. RAG or fine-tuning: skills are prescriptive (they tell the agent *what to do*), not just informational (here's some context, figure it out). That's why they produce consistently better outputs.

---

### Slide 6: AKS Best Practices Skill — Deep Dive

**Hook:** What if every engineer on your team made the same Day-0 decisions as your most senior AKS architect?

**Key Points:**

- **What It Covers** — Production-grade guidance across five pillars: **Networking** (CNI selection, service mesh, DNS), **Upgrade Strategy** (node surge, PDB configuration, maintenance windows), **Security** (workload identity, network policies, pod security), **Reliability** (availability zones, node pool design, health probes), and **Scaling** (cluster autoscaler tuning, KEDA, VPA vs. HPA).
- **Source of Truth** — This isn't crowd-sourced Stack Overflow advice. The guidance reflects what the *AKS engineering team themselves recommend* for production clusters — the same defaults and decision trees they use internally.
- **Contextual, Not Generic** — The skill doesn't dump a wall of text. It responds to *your specific question* with targeted guidance. Ask "What networking setup is best for my AKS cluster?" and it walks you through the decision tree: CNI Overlay vs. Azure CNI vs. kubenet, based on your constraints.
- **Always Current** — Skills update independently of the LLM's training data. When AKS ships a new feature or deprecates a pattern, the skill is updated — your agent's advice stays current without retraining.

**Example Prompt Flow:**
```
Engineer: "Help me determine Day-0 decisions for a new AKS cluster."
Agent (with skill loaded):
  → Walks through networking, identity, node pool topology
  → Recommends specific AKS defaults for production
  → Flags common anti-patterns to avoid
  → Produces a checklist the team can review before provisioning
```

**Slogan:** *Your best architect's playbook — loaded into every agent, every time.*

**Visual Idea:** A five-pillar temple graphic — each pillar labeled (Networking, Upgrades, Security, Reliability, Scaling) supporting a roof labeled "Production-Grade AKS." At the base: "AKS Engineering Team Recommendations." Subtle glow on whichever pillar the current prompt targets.

**Speaker Notes:**
> This is your credibility slide. Stress "AKS engineering team" — this isn't generic Kubernetes advice, it's opinionated guidance from the people who build the service. Walk through the example prompt flow live if possible. The audience should feel: "If I had this last quarter, I wouldn't have spent two weeks on that networking redesign."

---

### Slide 7: AKS Troubleshooting Skill — Deep Dive

**Hook:** At 2 AM, your on-call engineer shouldn't need to *remember* the diagnostic sequence — the agent should *know* it.

**Key Points:**

- **What It Covers** — The most common incident scenarios: **Node Health Failures** (NotReady nodes, kubelet crashes, VM extension failures, disk pressure, memory pressure) and **Networking Issues** (DNS resolution failures, pod-to-pod connectivity, ingress misconfigurations, NSG conflicts, service mesh routing).
- **Engineer-Grade Diagnostics** — The skill includes the *exact CLI commands and diagnostic sequences* that AKS support engineers use when working real customer incidents. Not approximations — the actual workflow, in the correct order, with the correct flags.
- **Permission-Gated Safety** — The skill only suggests and executes commands your current credentials allow. Read-only RBAC? It runs read-only diagnostics. No cluster access? It falls back to Azure Resource Manager queries. Zero risk of unintentional changes.
- **Structured Reasoning** — The skill doesn't just run commands — it *interprets* results. Node showing `MemoryPressure`? The skill knows to check the eviction thresholds, correlate with pod resource requests, and suggest whether to resize the node pool or adjust workload limits.

**Example Prompt Flow:**
```
Engineer: "Why is my node NotReady?"
Agent (with skill loaded):
  → Runs: kubectl get nodes -o wide
  → Runs: kubectl describe node <node-name>
  → Checks: kubelet status, VM extension health, disk/memory conditions
  → Correlates: recent deployments, resource pressure events
  → Recommends: cordon + drain if hardware, restart kubelet if transient
```

**Slogan:** *Your best on-call engineer's instincts — codified, consistent, and never tired.*

**Visual Idea:** A "decision tree" flowchart overlaid on a terminal screenshot — showing the branching diagnostic path the skill follows: `Node NotReady → Check kubelet → Check VM extension → Check disk pressure → ...` with the agent auto-navigating the tree based on what it finds.

**Speaker Notes:**
> This is the emotional peak of the Skills section. Every platform engineer in the room has been the 2 AM on-call person. Paint that picture — then show how the skill eliminates the "where do I even start?" moment. Stress permission-gating for any security-conscious audience. If you can, show a 60-second live demo: paste "why is my node NotReady?" and let the skill run.

---

### Slide 8: Before & After — The AI-Native Workflow Shift

**Hook:** Same incident. Two workflows. One takes 45 minutes, the other takes 3.

**Key Points:**

- **Before (Manual Workflow):**
  1. Alert fires → engineer opens laptop → SSH into bastion → `kubectl get nodes` → Google the error → read 4 Stack Overflow threads → try 3 commands → escalate to senior engineer → wait for response → apply fix → verify → close ticket. **Time: 30–60 minutes. Knowledge retained: minimal.**
  2. New cluster request → engineer opens docs → reads 12 pages on networking → makes a decision → PR review catches 3 anti-patterns → rework → deploy → discover the 4th anti-pattern in production. **Time: days. Consistency: none.**

- **After (AI-Native Workflow with Skills):**
  1. Alert fires → engineer opens Copilot → "Why is my node NotReady?" → skill loads, runs diagnostics, correlates events → presents root cause + remediation → engineer approves → fix applied → incident closed. **Time: 2–5 minutes. Knowledge captured: permanently.**
  2. New cluster request → engineer opens Copilot → "Help me with Day-0 decisions for a production AKS cluster" → skill walks through every pillar → produces a validated checklist → PR passes first review. **Time: minutes. Consistency: guaranteed.**

- **The Compound Effect** — Every interaction with a skill-powered agent *teaches the workflow* to the engineer while solving the immediate problem. Over months, your junior engineers develop senior-level instincts — not because they memorized docs, but because the skill modeled expert reasoning hundreds of times.

**Slogan:** *Forty-five minutes to three. That's not optimization — that's a paradigm shift.*

**Visual Idea:** Split-screen animation — left side shows the "Before" timeline (long, branching, frustrated engineer), right side shows the "After" timeline (short, linear, confident engineer). A clock at the top fast-forwards on the left, barely moves on the right.

**Speaker Notes:**
> Use real numbers if you have them from your own team. If not, the 45-to-3 framing is conservative — most teams report even bigger deltas for complex incidents. The compound effect point is your strategic closer: skills don't just fix the current incident, they *build the team's capability over time*. That's how you sell this to leadership.

---

### Slide 9: Build Your Own Skills — Extending the Blueprint

**Hook:** AKS skills are the starting point. The real power is encoding *your organization's* operational DNA.

**Key Points:**

- **What Makes a Good Custom Skill:**
  - **Governance Rules** — Your tagging standards, approved regions, allowed VM SKUs, mandatory labels. The agent enforces them at design time, not after a failed policy audit.
  - **Security Policies** — Your specific network isolation patterns, identity requirements, image provenance rules. The agent applies them consistently across every cluster, every team.
  - **Platform Standards** — Your DNS conventions, ingress controller configuration, observability stack setup (Prometheus + Grafana? Azure Monitor? Both?). The agent knows your golden path.
  - **Incident Runbooks** — Your team's hard-won troubleshooting playbooks, encoded as structured reasoning. The next on-call engineer gets the benefit of every past incident.

- **How It Works** — A skill is a structured markdown file (SKILL.md) placed in a known directory. Any compatible agent discovers it automatically. No API integration, no webhook plumbing, no SDK.
- **Token-Efficient by Design** — Skills use structured prompts, not massive document dumps. A well-written skill is 2–5 KB — small enough to load in any context window, rich enough to shape expert reasoning.
- **Institutional Knowledge Insurance** — When your senior engineer leaves, their expertise doesn't walk out the door. It lives in the skills they helped encode. Every departure becomes an *addition to the knowledge base*, not a subtraction from it.

**Slogan:** *Your runbooks shouldn't live in a wiki nobody reads. They should live in the agent everyone uses.*

**Visual Idea:** A "skill factory" conveyor belt — on one end: raw inputs (runbooks, wiki pages, incident reports, policy docs). On the conveyor: a transformation step labeled "Encode as Skill." On the other end: structured skill blocks being loaded into multiple agents (Copilot, Claude, CLI).

**Speaker Notes:**
> This is your call-to-action slide for the Skills section. You want the audience leaving this section thinking: "I need to encode our top 5 runbooks as skills this quarter." Walk through the simplicity — it's just a markdown file, no SDK, no API. Lower the barrier. If time permits, show the directory structure: `~/.copilot/skills/my-org-governance/SKILL.md`.

---

### Slide 10: The Skills Ecosystem — Where Skills Fit in the Stack

**Hook:** Skills are the knowledge layer. They're powerful alone — and transformational when combined with MCP and the Agentic CLI.

**Key Points:**

- **The Three Gears:**

| Gear | Role | Requires Cluster | Superpower |
|---|---|---|---|
| **AKS Skills** | Knowledge | No | Tells the agent *what to do* — best practices, diagnostics, guardrails |
| **AKS MCP Server** | Tools | Yes | Gives the agent *eyes and hands* — live cluster state, API access |
| **Agentic CLI for AKS** | Experience | Yes | Packages it all into *one command* — `az aks agent "fix my cluster"` |

- **Skills Alone** — Even without a cluster connection, skills dramatically improve agent output quality. An engineer designing a cluster in a PR gets production-grade guidance. A team writing Terraform gets AKS-specific defaults. Skills work *before* the cluster exists.
- **Skills + MCP** — This is where it gets powerful. The skill tells the agent *how* to diagnose a node failure. MCP gives the agent *access* to the actual node state. Together: the agent reasons like a senior engineer *and* sees what a senior engineer would see.
- **Skills + MCP + CLI** — The full stack. One command in a terminal triggers the skill, connects via MCP, runs diagnostics, proposes a fix, and waits for human approval. The engineer's role shifts from *doing the work* to *approving the work*.

- **Getting Started Is One Command:**
  ```bash
  # Via GitHub Copilot for Azure (recommended — includes 20+ Azure skills)
  # Just install the extension — skills auto-activate on AKS prompts

  # Or install directly:
  npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-kubernetes
  npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-diagnostics
  ```

**Slogan:** *Knowledge. Context. Action. Three gears, one engine.*

**Visual Idea:** An interlocking gear diagram — three gears meshing together labeled "Skills (Knowledge)," "MCP (Context)," and "CLI (Action)." When all three turn, a central output shaft labeled "Autonomous Operations" spins. Each gear can spin alone (dimmer), but the output shaft only turns when all three engage.

**Speaker Notes:**
> This is your transition slide — you're handing off from the "why and what" of Skills to the "how" of MCP and CLI in the next sections. End with the installation command on screen. Make it tangible: "You can have this running in your environment in under two minutes." Pause. Let the audience absorb that the barrier to entry is essentially zero. Then tease: "But Skills are just the knowledge layer. In the next section, we'll give the agent *eyes* — with the AKS MCP Server."

---

*This section established that AKS Skills are the foundation of AI-native operations: portable, composable, open-standard packages that turn any agent into an AKS expert — and that the real unlock is encoding your own organization's expertise on top of them.*

---
---

## Section 3: The Context Layer — Mastering the AKS MCP Server (Giving the Agent Eyes)

> *"An agent without cluster access is an expert with a blindfold. MCP removes the blindfold."*

---

### Slide 11: Why Context Changes Everything

**Hook:** Skills tell the agent *what to do*. MCP tells the agent *what's actually happening*.

**Key Points:**

- **The Blindfold Problem** — Without live cluster access, an agent with skills is like a doctor diagnosing over the phone: knowledgeable, but guessing. It can tell you the *typical* causes of a NotReady node, but it can't tell you *your* node has disk pressure because a log volume filled up overnight.
- **What MCP Actually Is** — Model Context Protocol (MCP) is a standardized interface that lets AI agents invoke tools securely. The AKS MCP Server exposes cluster operations as structured tools that any MCP-compatible agent (Copilot, Claude, Gemini) can call. Think of it as a "typed API for AI" — not free-form shell commands, but scoped, permission-aware operations with structured inputs and outputs.
- **From Hypothetical to Specific** — With MCP, the agent doesn't say "you might want to check your node conditions." It *checks* node conditions, reads the events, pulls the metrics, and says "Node `aks-nodepool1-vmss000002` has been in MemoryPressure for 47 minutes; 3 pods were evicted at 03:12 UTC; here's the remediation."
- **The Bridge Between Knowledge and Reality** — Skills + MCP = the agent reasons with expert knowledge *about your actual environment*. This is the compound effect: the more context the agent has, the more precisely it applies its skills.

**Slogan:** *Skills give the agent a brain. MCP gives it eyes.*

**Visual Idea:** A split-screen — Left: an agent responding with generic advice ("Possible causes of NotReady: disk pressure, network issues, kubelet crash..."). Right: the same agent with MCP, responding with specific data ("Node aks-np1-vmss000002: MemoryPressure since 03:12 UTC, 3 pods evicted, current memory at 94%"). A label on the bridge between them: "MCP."

**Speaker Notes:**
> This is the "aha" slide. You're building on the Skills foundation from Section 2 and showing the audience what happens when the agent can actually *see* their cluster. Use the doctor analogy — it lands universally. The goal: by the end of this slide, the audience should be thinking "I need this connected to my clusters."

---

### Slide 12: The AKS MCP Server — What It Exposes

**Hook:** One server. Twelve tool categories. Every angle of your AKS cluster, accessible to any AI agent.

**Key Points:**

- **Unified Tool Architecture** — The AKS MCP Server provides two unified tools as its primary interface: `call_az` (Azure CLI operations) and `call_kubectl` (Kubernetes operations). These give agents flexible, full-spectrum access without needing to learn dozens of specialized endpoints.
- **Specialized Tool Categories:**

| Tool | What It Sees | Why It Matters |
|---|---|---|
| `call_az` / `call_kubectl` | Full Azure CLI + kubectl | Unified interface for any operation |
| `aks_network_resources` | VNets, subnets, NSGs, route tables, load balancers, private endpoints | Network topology at a glance |
| `aks_monitoring` | Metrics, resource health, App Insights, control plane logs, diagnostics | Observability without dashboard-hopping |
| `get_aks_vmss_info` + `collect_aks_node_logs` | VMSS config, kubelet/containerd/kernel/syslog logs | Deep node-level debugging |
| `aks_detector` | 8 diagnostic categories (Node Health, Connectivity, Security, etc.) | AKS-native health checks |
| `aks_advisor_recommendation` | Cost, HighAvailability, Performance, Security recommendations | Azure Advisor insights on demand |
| `az_fleet` | Fleet operations, member clusters, update runs, resource placement | Multi-cluster management |
| `inspektor_gadget_observability` | DNS, TCP, file I/O, process execution, syscalls, packet capture (eBPF) | Real-time kernel-level observability |
| `call_helm` / `call_cilium` / `call_hubble` | Helm releases, Cilium networking, Hubble flow visibility | Full ecosystem integration |

- **Access Control Built In** — Three access levels: `readonly` (safe for any agent), `readwrite` (operational tasks), `admin` (credential management). The access level is configured once in `mcp.json` — every tool call respects it. No risk of an agent accidentally deleting a node pool in read-only mode.
- **eBPF-Powered Deep Observability** — Inspektor Gadget integration lets the agent observe DNS queries, TCP connections, file operations, process execution, and even raw packet captures — all via eBPF, with zero instrumentation overhead. This is the level of visibility that previously required a dedicated SRE with specialized tooling.

**Slogan:** *Twelve tools. One interface. Every layer of your cluster.*

**Visual Idea:** A radial diagram with "AKS MCP Server" at the center. Twelve spokes radiate outward, each labeled with a tool category and a small icon (network, monitor, compute, fleet, etc.). The outer ring shows the access levels as concentric circles: readonly (outer, green), readwrite (middle, amber), admin (inner, red).

**Speaker Notes:**
> Don't try to cover every tool — pick 3-4 that resonate with your audience. For networking-heavy teams, emphasize `aks_network_resources` and Hubble. For ops-heavy teams, emphasize `aks_detector` and `collect_aks_node_logs`. For multi-cluster teams, emphasize `az_fleet`. The point isn't to memorize the table — it's to understand that the agent can see *everything* they'd normally have to check manually across 6 different dashboards and CLIs.

---

### Slide 13: How It Works — Architecture & Authentication

**Hook:** Secure by default. Authenticated by design. Zero credentials stored in the agent.

**Key Points:**

- **Architecture Flow:**
  ```
  VS Code / CLI / Any MCP Client
        ↓ (MCP Protocol - stdio or HTTP)
  AKS MCP Server (local binary or in-cluster pod)
        ↓ (Azure SDK + kubectl)
  Azure Resource Manager API ←→ Kubernetes API Server
        ↓                              ↓
  AKS Control Plane          Cluster Workloads & State
  ```

- **Authentication Chain** — The MCP server inherits your existing Azure identity. Five methods, tried in order: Service Principal → Workload Identity (federated token) → User-Assigned Managed Identity → System-Assigned Managed Identity → Existing `az login` session. No new credentials to manage. No secrets in config files.
- **Two Deployment Models:**
  1. **Local (stdio)** — The MCP server runs as a local binary alongside VS Code. Simplest to set up. Uses your local `az login` credentials. Best for individual developers.
  2. **Remote (in-cluster)** — The MCP server runs as a pod inside the AKS cluster itself, using Workload Identity for authentication. Centralized, scalable, multi-user. Best for platform teams.
- **One-Click Setup** — Via the AKS VS Code Extension: `Command Palette → AKS: Setup AKS MCP Server`. Binary download, configuration, and registration happen automatically.

**Slogan:** *Your identity. Your permissions. The agent just borrows them.*

**Visual Idea:** A security architecture diagram showing the trust chain: User Identity (Azure AD) → az login / Workload Identity → MCP Server → Azure APIs. A "no secrets stored" badge on the MCP Server box. Side-by-side comparison of Local (laptop icon) vs. Remote (cluster icon) deployment.

**Speaker Notes:**
> Security teams will scrutinize this slide. Stress three things: (1) no new credentials — the agent uses your existing identity, (2) access levels are configurable and enforced server-side, (3) every operation is auditable through standard Azure activity logs. For the remote deployment model, mention Workload Identity + federated tokens — this is the enterprise pattern.

---

### Slide 14: Live Demo Scenario — MCP in Action

**Hook:** Let's stop talking about it and watch the agent diagnose a real cluster.

**Key Points:**

- **Demo Setup:**
  - AKS cluster with a deliberately unhealthy node (simulated disk pressure)
  - AKS MCP Server running locally (stdio mode)
  - GitHub Copilot in Agent mode with AKS skills loaded

- **Demo Flow:**
  ```
  Engineer: "What's the health status of my AKS cluster?"

  Agent (via MCP):
    → Calls call_az: az aks list (finds the cluster)
    → Calls call_kubectl: kubectl get nodes -o wide (spots NotReady node)
    → Calls call_kubectl: kubectl describe node <name> (reads conditions)
    → Calls aks_detector: runs node-health-detector (correlates events)
    → Calls collect_aks_node_logs: pulls kubelet logs, filters for ERROR
    → Synthesizes: "Node aks-np1-vmss000003 is NotReady due to DiskPressure.
       Root cause: /var/log volume at 98%. 4 pods evicted in last hour.
       Recommended: Increase OS disk size or enable ephemeral OS disks
       for this node pool."
  ```

- **What the Audience Should Notice:**
  1. The agent decided *which* tools to call and *in what order* — it wasn't scripted
  2. Each tool call was permission-aware (readonly access level)
  3. The final answer is *specific to this cluster* — not a generic doc link
  4. Total time: ~15 seconds for what would take a human 10–20 minutes

**Slogan:** *Fifteen seconds. Six tool calls. Zero guesswork.*

**Visual Idea:** A live terminal recording (or animated GIF) showing the Copilot chat panel with the MCP tool calls expanding in real-time. Each tool call shows a brief result summary. The final synthesized answer appears at the bottom, highlighted.

**Speaker Notes:**
> If you can do this live, do it. Nothing sells MCP like watching it work in real-time. If not live, use a pre-recorded terminal session. Key moment: when the agent chains multiple tools autonomously — pause and point this out. "Notice it didn't ask me which tool to use. It decided based on what it found in the previous step." That's the agentic behavior. That's the difference.

---

### Slide 15: Deployment Patterns — Local vs. Remote vs. Hybrid

**Hook:** Start local in 60 seconds. Scale to remote when the team grows.

**Key Points:**

- **Pattern 1: Local (Developer Workstation)**
  - Install via AKS VS Code Extension (one click) or download binary manually
  - Runs alongside VS Code, uses local `az login`
  - Best for: individual developers, proof of concept, demos
  - Limitation: one user, one machine, credentials tied to local session

- **Pattern 2: Remote (In-Cluster)**
  - Deploy as a pod in AKS using Helm chart or kubectl manifests
  - Authenticate via Workload Identity (federated tokens, zero secrets)
  - Expose via ClusterIP service + port-forward (dev) or ingress (production)
  - Best for: platform teams, shared environments, multi-user access
  - Advantage: centralized control, audit logging, consistent access levels

- **Pattern 3: Hybrid (Recommended for Enterprise)**
  - Local MCP for day-to-day development and quick queries
  - Remote MCP for shared incident response, on-call workflows, and CI/CD integration
  - Both instances share the same tool interface — agents don't know the difference
  - Best for: organizations with multiple teams, clusters, and access levels

- **Getting Started (Fastest Path):**
  ```powershell
  # Install AKS Extension in VS Code
  # Command Palette → "AKS: Setup AKS MCP Server"
  # Done. Start prompting.
  ```

**Slogan:** *Sixty seconds to start. Enterprise-ready when you need it.*

**Visual Idea:** A maturity ladder with three rungs: "Local (Day 1)" → "Remote (Day 30)" → "Hybrid (Day 90)." Each rung shows the deployment topology, user count, and governance level increasing as you climb.

**Speaker Notes:**
> Match the pattern to the audience. If they're developers, lean into Pattern 1 — show how fast it is. If they're platform leads, lean into Pattern 2 — show Workload Identity and centralized governance. If they're enterprise architects, show Pattern 3 — the hybrid model with separation of concerns. The key message: you don't have to boil the ocean. Start local, graduate to remote.

---

*This section proved that MCP is the context layer that transforms an agent from a knowledgeable advisor into a situationally-aware operator — with secure authentication, granular access control, and zero-config setup.*

---
---

## Section 4: The Action Layer — The Agentic CLI for AKS (Giving the Agent Hands)

> *"Skills give the agent a brain. MCP gives it eyes. The CLI gives it hands."*

---

### Slide 16: Why the CLI Agent Exists — AKS's Mission Meets AI

**Hook:** AKS's mission is to "enable developers, SREs, DevOps and platform engineers to do more with AKS." AI is the single biggest force multiplier we've seen in a generation. The CLI Agent is how we put it in your hands.

**Key Points:**

- **The Pain That Demanded This** — Troubleshooting Kubernetes is notoriously complex. AKS customers — from cloud-native startups to large enterprises — face the same recurring pain: overwhelming *signal fragmentation* (correlating metrics, logs, and traces across layers and tools), a lack of the *deep Kubernetes + Azure expertise* needed to interpret all of these signals, and the *manual tool-wrangling* across CLIs, dashboards, and portals that drives up mean-time-to-resolution (MTTR) and support costs. Existing tools surface raw data but lack built-in intelligence to guide users through diagnosis *and* resolution.
- **Depth Over Breadth — An Intentional Choice** — The team faced an early tradeoff: solve broadly (all AKS interactions) or solve *deeply* in the areas that hurt the most. They chose depth — starting with troubleshooting, the #1 pain point where agentic AI is most promising. Internally, the project was first called the **"AKS AI Troubleshooter."** Four focused problem domains drive the first release:



- **And the Breadth Is Coming** — In parallel, the team is building a table-stakes experience for general Kubernetes and AKS use cases (cost optimization, configuration, day-to-day operations). The depth-first strategy ensures the hardest problems are solved *well* before expanding — and early-access feedback shapes what comes next.
- **The Result: A Purpose-Built Terminal Experience** — `az aks agent` is an AI-powered command-line experience that brings secure, extensible, and intelligent agentic workflows directly to your terminal. Describe the problem in natural language. The agent diagnoses, proposes, and — with your approval — resolves it.

**Slogan:** *AI is the biggest force multiplier in a generation. This is how AKS puts it in your hands.*

**Visual Idea:** The "target-customer-pain-points" and "target-customer-benefits" graphics from the CLI Agent blog (if available), or a custom version: Left panel shows three pain pillars (Signal Fragmentation, Expertise Gap, Tool Sprawl) in red. Right panel shows the CLI Agent absorbing all three and outputting a single, clean resolution in green. The four troubleshooting domains appear as focused target icons below.

**Speaker Notes:**
> Start with the mission statement — it grounds the conversation in customer value, not technology. Then walk through the four troubleshooting domains with a quick real-world story for each: "Raise your hand if you've spent 20 minutes trying to figure out why a pod is stuck in Pending. That's domain #3." The "AKS AI Troubleshooter" internal codename is a humanizing detail — it shows this wasn't a marketing exercise; it started as an engineering response to real pain. Mention that feedback from the limited preview directly shapes what domains are prioritized next — this makes the audience feel invested.

---

### Slide 17: Built on Open Source — The Lego-Block Architecture

**Hook:** Should we build something proprietary or contribute in the open source community? This was a simple decision — "Working in the Open Source community" is a core product pillar for AKS.

**Key Points:**

- **The Agent Framework: HolmesGPT** — [HolmesGPT](https://github.com/robusta-dev/holmesgpt) is an open-source agentic AI framework that performs root cause analysis (RCA), executes diagnostic tools, and synthesizes insights using natural language prompts. The AKS team evaluated several open-source solutions and built internal prototypes before choosing to partner with [Robusta.dev](https://www.robusta.dev/) on HolmesGPT. Why HolmesGPT won:
  - Highly extensible architecture with built-in support for modular toolsets, MCP servers, and custom runbooks
  - Comprehensive prompts tailored specifically for Kubernetes environments
  - An active and collaborative open-source community
  - **Microsoft's AKS team is now a co-maintainer** of HolmesGPT, and Robusta has donated it to **CNCF as a Sandbox project**

- **The Tools & Capabilities: AKS-MCP Server** — The AKS MCP Server (Section 3) provides the secure, protocol-first bridge between AI agents and AKS clusters — exposing Kubernetes and Azure APIs, observability signals, and diagnostic tools via a standardized interface. HolmesGPT + AKS-MCP are the two building blocks.

- **The Lego-Block Architecture:**
  ```
  ┌─────────────────────────────────────────────────┐
  │           az aks agent (CLI interface)           │
  ├─────────────────────────────────────────────────┤
  │  HolmesGPT Agent Framework (CNCF Sandbox)       │
  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
  │  │ Runbooks │ │  Prompts │ │ Reasoning Engine │ │
  │  └──────────┘ └──────────┘ └──────────────────┘ │
  ├─────────────────────────────────────────────────┤
  │  AKS-MCP Server (Tools & Capabilities)           │
  │  ┌────────┐ ┌─────────┐ ┌──────────┐ ┌───────┐ │
  │  │call_az │ │kubectl  │ │detectors │ │gadgets│ │
  │  └────────┘ └─────────┘ └──────────┘ └───────┘ │
  ├─────────────────────────────────────────────────┤
  │  Your AI Provider (BYOM)                         │
  │  Azure OpenAI │ OpenAI │ Anthropic │ Any LLM    │
  ├─────────────────────────────────────────────────┤
  │  Your Observability Stack (Pluggable)            │
  │  Prometheus │ Datadog │ Dynatrace │ Custom      │
  └─────────────────────────────────────────────────┘
  ```

- **Why Lego Blocks Matter** — Every layer is swappable. Don't like the AI model? Bring your own. Have Datadog instead of Prometheus? Plug it in. Want custom diagnostic workflows? Add runbook plugins. The architecture is opinionated about *how* the pieces connect (MCP protocol, standardized tool interfaces) but unopinionated about *which* pieces you use.

**Slogan:** *Open source at every layer. Proprietary at none.*

**Visual Idea:** The "cli-agent-lego-blocks" graphic from the blog — or a custom version showing the layered architecture as literal Lego bricks, each labeled with a component. The bricks snap together but can be individually swapped. HolmesGPT and AKS-MCP bricks are highlighted with CNCF and Azure logos respectively.

**Speaker Notes:**
> This slide matters enormously for technical audiences. Lead with the decision: "We could have built this proprietary. We chose open source." Then explain *why* HolmesGPT — the due diligence process (evaluated multiple frameworks, built prototypes) shows this wasn't a casual choice. The CNCF Sandbox donation is a powerful signal: this isn't "Microsoft open source" — it's community-governed open source that Microsoft co-maintains. The lego-block diagram should be your anchor visual — keep it on screen while you walk through each layer. Emphasize the BYOM and pluggable observability rows: "You are never locked in. Not to our model, not to our monitoring stack, not to our framework."

---

### Slide 18: The CLI in Action — Commands, Capabilities, & Extensibility

**Hook:** One command. Natural language. Four troubleshooting domains today — and an extensible platform for everything else tomorrow.

**Key Points:**

- **Getting Started:**
  ```bash
  az aks agent --help
  # or dive straight in:
  az aks agent "how is my cluster [Cluster-name] in resource group [RG-name]?"
  ```

- **Troubleshooting Commands (Depth-First):**
  ```bash
  # 🧠 Node Health
  az aks agent "why is one of my nodes in NotReady state?"

  # 🌐 DNS & Networking
  az aks agent "why are my pods failing DNS lookups?"

  # 🕵️ Pod Scheduling
  az aks agent "why is my pod stuck in Pending state?"

  # 🔄 Cluster CRUD & Upgrades
  az aks agent "my AKS cluster is in a failed state, what happened?"
  ```

- **General Operations (Breadth):**
  ```bash
  # Cost Optimization
  az aks agent "how can I optimize the cost of my cluster?"

  # Cluster Health
  az aks agent "give me a health summary of my production cluster"
  ```

- **Extensibility — Adapt to Your Environment:**
  - **Custom Toolsets** — Easily configure integrations with Prometheus, Datadog, Dynatrace, or your proprietary observability platform. The agent can pull metrics and alerts from *your* stack, not just Azure Monitor.
  - **Runbook Plugins** — Add your organization's troubleshooting workflows as runbook plugins. The agent follows your internal playbooks, not just generic Kubernetes advice. Community-contributed runbooks are also available.
  - **MCP Server Support** — Connect additional MCP servers for advanced diagnostics: AppLens detectors, Azure Monitor queries, debug pod deployment. The agent's tool surface is as wide as you make it.

- **What Happens Under the Hood:**
  ```
  You say: "why is my pod stuck in Pending?"
  
  Agent (HolmesGPT + AKS-MCP):
    → Loads Kubernetes scheduling prompts
    → Calls kubectl: get pods --field-selector=status.phase=Pending
    → Calls kubectl: describe pod <name> — reads Events
    → Calls kubectl: get nodes — checks capacity vs. requests
    → Checks: affinity rules, taints/tolerations, PDBs, zone constraints
    → Synthesizes: "Pod 'api-worker-7f8d9' can't be scheduled: 
       requests 8 vCPU but largest available node has 4 vCPU free.
       Node pool 'workload' has 3/5 nodes at >90% CPU.
       Options: (1) Scale node pool to 7 nodes, (2) Reduce pod 
       CPU request to 4 vCPU, (3) Add a new node pool with 
       Standard_D16s_v5 SKU"
    → Waits for your approval before any changes
  ```

**Slogan:** *Your problems. Your tools. Your runbooks. One agent that ties them all together.*

**Visual Idea:** A terminal recording showing a real `az aks agent` session. The prompt at top, the agent's diagnostic chain expanding in the middle (each tool call as a collapsible step with a brief result), and the final synthesized answer with options at the bottom. A sidebar callout highlights the extensibility layer: "Plug in Datadog, your runbooks, additional MCP servers."

**Speaker Notes:**
> Structure this as a live demo if possible. Start with `az aks agent --help` to show the simplicity. Then pick one of the four troubleshooting domains (node NotReady or pod Pending land best) and run it live. As the agent chains tools, narrate what's happening: "It's pulling pod events... now checking node capacity... now correlating with affinity rules." Pause on the final synthesis — "Notice: it didn't give me a doc link. It gave me three specific options ranked by impact." Then quickly flash the extensibility points: "And if you use Datadog instead of Prometheus, or have internal runbooks, those plug right into this same experience." The under-the-hood breakdown should feel like *x-ray vision* into the agent's reasoning.

---

### Slide 19: Designing for Safety — Why We Started with a CLI

**Hook:** Our long-term vision is an autonomous, AI-powered auto-healing system — a true "SRE-as-a-service" for AKS. Our first step is intentionally cautious.

**Key Points:**

- **Why CLI First, Not Autonomous** — In production environments, the cost of failure is high. Automated actions without human oversight can lead to unintended disruptions, especially when AI agents misinterpret telemetry or act on incomplete data. Recent public incidents across the industry have reaffirmed this: *autonomy without accountability is risky.* The CLI is the safest first step because the human is always in the loop.

- **The Three Pillars of Trust:**

| Pillar | What It Means | How It's Enforced |
|---|---|---|
| **Transparency** | Users see exactly what tools were run and what data was analyzed | Every tool call is logged and displayed in the agent's reasoning chain |
| **Control** | No changes are made to the cluster without explicit user permission | All mutating operations require `[Y/n]` approval before execution |
| **Trust** | AI outputs are grounded in real telemetry, not hallucinated advice | Recommendations include supporting evidence (logs, metrics, events) |

- **Security & Privacy — Non-Negotiable:**
  - **Runs Locally** — All diagnostics and data collection are performed on your machine. Data is sent only to *your* configured LLM. It is **not** sent to or stored in AKS systems.
  - **Azure CLI Auth** — Inherits your Azure identity and RBAC permissions. The agent can only access what *you* can access.
  - **Bring Your Own AI (BYOM)** — You configure your own AI provider (Azure OpenAI, OpenAI, Anthropic, etc.). No user data is retained by Microsoft. You can bring LLMs approved by your organization — including Azure OpenAI instances deployed in your own subscriptions and virtual networks.

- **The Maturity Roadmap:**
  ```
  Today                    Near-Term                  Vision
  ┌──────────────┐    ┌──────────────────┐    ┌───────────────────┐
  │  CLI Agent   │ →  │  Assisted Auto-  │ →  │  SRE-as-a-Service │
  │  (Human-in-  │    │  Remediation     │    │  (Autonomous      │
  │   the-loop)  │    │  (Approve once,  │    │   auto-healing    │
  │              │    │   agent executes  │    │   with guardrails)│
  │              │    │   similar fixes)  │    │                   │
  └──────────────┘    └──────────────────┘    └───────────────────┘
       You are here         Coming next           Long-term vision
  ```

- **Your Feedback Shapes the Journey** — The CLI Agent is in limited preview. The AKS team is actively gathering feedback to validate the AI's reasoning and iterate safely. Sign up: **[aka.ms/cli-agent/signup](https://aka.ms/cli-agent/signup)**

**Slogan:** *Autonomy is the destination. Accountability is the road we take to get there.*

**Visual Idea:** The maturity roadmap as a horizontal timeline with three stages, each with an icon: a hand on the steering wheel (CLI, today), a hand hovering over the wheel (assisted, near-term), and the car driving itself with a safety net below (autonomous, vision). The "You are here" marker sits firmly on stage 1.

**Speaker Notes:**
> This is the trust slide — the one that determines whether the audience leans in or pulls back. Open with the vision ("SRE-as-a-service, autonomous auto-healing") to get attention, then immediately ground it: "But we're not starting there. Here's why." Walk through the three pillars — transparency, control, trust — with a specific example for each. The privacy points are critical for regulated industries: "Your data never leaves your machine except to your own AI model. Not to us. Not to anyone." The maturity roadmap is your strategic anchor: "We will get to autonomous. But we'll earn that trust one stage at a time, with your feedback." End with the signup URL — make it a CTA: "If you want to shape what stage 2 looks like, join the preview."

---

### Slide 20: The Omnichannel Vision — CLI, VS Code, Portal

**Hook:** The CLI Agent is just the beginning. Our vision: intelligent AKS operations on every surface where our customers work.

**Key Points:**

- **The Omnichannel Strategy:**

| Surface | Experience | Status | Best For |
|---|---|---|---|
| **Agentic CLI** (`az aks agent`) | Terminal-first, natural language, HolmesGPT + AKS-MCP | ✅ Limited Preview | On-call engineers, automation pipelines, SSH sessions |
| **VS Code + Copilot** | Chat panel with AKS Skills + MCP tools | ✅ Available | Day-to-day development, cluster design, PR reviews |
| **Azure Portal** | Integrated agentic diagnostics via Copilot + Diagnose & Solve | 🔜 Coming | Management reviews, cross-subscription views, stakeholder demos |

- **Why Omnichannel Matters** — "We want to be where our customers are." Every user has a tool preference — some live in terminals, others in VS Code, others in the portal. The intelligence should follow the user, not force the user to follow the tool. The same Skills, the same MCP Server, the same reasoning engine — consistent and comprehensive wherever you are.

- **Same Brain, Different Hands:**
  - The AKS Skills layer is shared across all surfaces — the agent's knowledge is identical
  - The AKS-MCP Server provides the same tools whether called from the CLI, VS Code, or the portal
  - Start a diagnosis in VS Code, continue it in the CLI during an on-call session, review the results in the portal the next morning. No context loss. No re-diagnosis.

- **Pipeline Integration** — The Agentic CLI is embeddable in CI/CD pipelines, runbooks, and automation scripts. Imagine a post-deployment gate: `az aks agent "verify the deployment to production is healthy and all pods are running"` — the pipeline proceeds only if the agent confirms health. PagerDuty integration: the agent runs initial triage before waking a human.

**Slogan:** *Every surface. One intelligence. Your engineer's choice.*

**Visual Idea:** A triptych — three panels showing the same AKS diagnostic query being answered in three different surfaces: a terminal window (CLI with HolmesGPT reasoning chain), a VS Code Copilot chat panel (MCP tool calls), and an Azure Portal Diagnose & Solve blade. A shared "AKS Intelligence Layer" bar runs across the bottom connecting all three. Labels: "Same Skills. Same MCP. Same Answer."

**Speaker Notes:**
> Frame this as the strategic vision that makes the entire deck cohesive. Point back to previous sections: "In Section 2 you saw Skills — they work in VS Code today. In Section 3 you saw MCP — it works in VS Code and the CLI. In this section you saw the Agentic CLI — the terminal experience. Now imagine all three converging in the portal." The pipeline integration point is your enterprise closer: "Your deployment pipeline can include an AI-powered health gate. No human in the loop for read-only checks; the agent pages you only when something is wrong." Then transition: "We've shown this architecture with AKS. But your Kubernetes estate probably isn't AKS-only. Let's talk about ARO."

---

*This section showed that the CLI Agent for AKS — built on open-source HolmesGPT (CNCF Sandbox) and the AKS-MCP Server — closes the loop from diagnosis to action with human-in-the-loop safety, a lego-block architecture that's extensible at every layer, and a deliberate maturity roadmap from assisted operations to autonomous "SRE-as-a-service." The omnichannel vision ensures this intelligence meets engineers wherever they work.*

---
---

## Section 5: Extending the Reach — Applying the Pattern to ARO (Azure Red Hat OpenShift)

> *"The same intelligence architecture. A different Kubernetes distribution. Zero re-learning."*

---

### Slide 21: Why ARO Matters in This Story

**Hook:** Many enterprises run AKS *and* ARO. Your operational intelligence shouldn't stop at the distribution boundary.

**Key Points:**

- **The Hybrid Reality** — Enterprise Kubernetes is rarely single-distribution. Teams run AKS for cloud-native workloads and ARO for workloads that require Red Hat support, OpenShift-specific operators, or regulatory compliance tied to RHEL. Both need the same operational excellence.
- **The Consistency Tax** — Without a unified intelligence layer, platform teams maintain two sets of runbooks, two troubleshooting workflows, two mental models. Skill gained on one platform doesn't transfer to the other. Incidents take longer because the on-call engineer needs to remember "Is this an AKS cluster or an ARO cluster? Which commands do I run?"
- **The MCP Abstraction** — The AKS MCP architecture pattern is *portable*. The same concept — expose cluster operations as structured tools that AI agents can invoke — applies to any Kubernetes distribution. The ARO MCP Server proves it: same protocol, same agent interface, different cluster backend.
- **One Agent, Two Platforms** — An engineer using Copilot with both AKS MCP and ARO MCP loaded can ask "Check the health of all my clusters" — and the agent calls the right tools for each platform automatically. The distribution is an implementation detail, not a workflow barrier.

**Slogan:** *Your intelligence shouldn't have a distribution boundary.*

**Visual Idea:** A map showing two types of clusters (AKS icons and ARO icons) spread across Azure regions, all connected by MCP lines feeding into a single "Agent Intelligence" hub. The message: one brain, multiple platforms.

**Speaker Notes:**
> This slide is critical for enterprise audiences running both AKS and ARO. The emotional hook: "Raise your hand if you have both AKS and ARO clusters." Then: "Keep your hand up if your troubleshooting process is the same for both." Hands will drop. That's the problem you're solving.

---

### Slide 22: The ARO MCP Server — Deep Dive

**Hook:** The ARO MCP Server brings the same AI-powered operations model to Azure Red Hat OpenShift.

**Key Points:**

- **Available Tools:**

| Tool | Description | Powered By |
|---|---|---|
| `aro_cluster_get` | List all ARO clusters in a subscription, or get specific cluster details (profiles, networking, API server, worker nodes, provisioning state) | Azure Resource Manager API |
| `aro_cluster_diagnose` | AI-powered diagnosis of ARO cluster issues — sends cluster data + your question to GPT-4o for expert analysis | Azure OpenAI |
| `aro_cluster_summarize` | AI-powered cluster summary — health assessment, configuration overview, and actionable recommendations | Azure OpenAI |

- **What It Sees:**
  - Cluster profile (domain, version, FIPS mode)
  - API server profile (URL, IP, visibility — public or private)
  - Console URL
  - Network profile (pod CIDR, service CIDR, outbound type)
  - Master profile (VM size, subnet, encryption at host)
  - Worker profile (count, VM size, disk size)
  - Provisioning and cluster state

- **AI-Powered Diagnosis** — The `aro_cluster_diagnose` tool doesn't just return raw data. It sends cluster metadata to Azure OpenAI (GPT-4o), which analyzes the configuration against known patterns and returns a structured assessment: what's healthy, what's concerning, what to do next.
- **Flexible Authentication** — Two login modes: *Subscription Lookup* (uses `az login` to auto-retrieve kubeadmin credentials + exchange for OAuth token) or *Direct API Server Login* (provide the ARO API server URL + kubeadmin credentials). Passwords are always prompted via `Read-Host -AsSecureString` — never logged, never in shell history.

**Slogan:** *Three tools. Full cluster intelligence. OpenShift-native.*

**Visual Idea:** A side-by-side comparison: "AKS MCP Server" (left, with its 12 tool categories) and "ARO MCP Server" (right, with its 3 tools). Both connect to the same agent at the top. A shared label: "Same MCP Protocol." Below: a growth arrow on the ARO side labeled "Expanding."

**Speaker Notes:**
> Be honest about the current scope: ARO MCP has 3 tools vs. AKS MCP's 12 tool categories. That's intentional — it's a focused starting point. The value isn't the number of tools, it's the *pattern*: the same architecture, the same protocol, the same agent interface. As the ARO MCP Server matures, the tools will expand — but the engineer's workflow doesn't change. Mention that `aro_cluster_diagnose` uses Azure OpenAI — this resonates with enterprise teams already invested in the Azure AI stack.

---

### Slide 23: Cross-Platform Workflow — AKS + ARO Side by Side

**Hook:** One agent. One conversation. Two platforms. Zero context-switching.

**Key Points:**

- **Demo Scenario:**
  ```
  Engineer: "Give me a health summary of all my Kubernetes clusters."

  Agent (with AKS MCP + ARO MCP loaded):
    → Calls AKS MCP: az aks list → finds 3 AKS clusters
    → Calls ARO MCP: aro_cluster_get → finds 2 ARO clusters
    → For each cluster, retrieves health/provisioning state
    → Synthesizes:

    "You have 5 clusters across 2 platforms:

     AKS Clusters:
     ✅ aks-prod-eastus2 — Running, v1.31.4, 12 nodes, all healthy
     ✅ aks-staging-westus — Running, v1.30.8, 4 nodes, all healthy
     ⚠️ aks-dev-centralus — Running, v1.29.2 (EOL in 30 days), 2 nodes

     ARO Clusters:
     ✅ aro-prod-centralus — Succeeded, v4.15, 6 workers, FIPS enabled
     ⚠️ aro-staging-eastus — AdminUpdating, v4.14, 3 workers

     Recommendations:
     1. Upgrade aks-dev-centralus before v1.29 reaches EOL
     2. Monitor aro-staging-eastus — AdminUpdating may take 30-60 min"
  ```

- **The Unified View** — The engineer didn't need to switch tools, remember different commands, or mentally map between `kubectl` (AKS) and `oc` (ARO). The agent abstracted the platform differences and delivered a consolidated health report.
- **Cross-Platform Incident Response** — "Why is my application down?" The agent can trace the issue across both platforms: check AKS ingress, check ARO routes, compare configurations, identify the divergence.
- **Future: Unified Fleet Operations** — As both MCP servers mature, the agent will be able to execute cross-platform operations: "Upgrade all my non-production clusters to the latest patch version" — targeting both AKS and ARO automatically.

**Slogan:** *Two platforms. One conversation. Zero excuses.*

**Visual Idea:** A unified dashboard mockup showing AKS and ARO clusters in a single view, with health indicators (green/amber/red), version info, and recommended actions. A banner at the top: "Powered by MCP — AKS + ARO."

**Speaker Notes:**
> This is your "drop the mic" slide for the cross-platform story. The demo scenario is powerful because it's *mundane* — this is something every multi-platform team does manually every week. Show how the agent eliminates the cognitive overhead of context-switching between platforms. If the audience runs only AKS, emphasize that the pattern extends to *any* MCP-compatible platform — ARO is just the first proof point.

---

*This section proved that the Skills + MCP pattern isn't AKS-specific — it's a universal architecture for AI-native Kubernetes operations that works across distributions and platforms.*

---
---

## Section 6: Real-World Scenarios — From Zero-Day Setup to "Self-Healing" Troubleshooting

> *"Theory is convincing. But a 2 AM incident is where this earns its keep."*

---

### Slide 24: Scenario 1 — Day-0: Production Cluster Provisioning

**Hook:** A new team needs a production AKS cluster. Instead of a 3-week design review, the agent walks them through it in 30 minutes.

**Key Points:**

- **The Workflow:**
  ```
  Engineer: "I need to set up a new production AKS cluster for our 
  payment processing service. High availability, PCI-compliant, 
  private networking."

  Agent (Skills loaded, no cluster yet):
    → Loads AKS Best Practices skill
    → Walks through Day-0 decision tree:
      ✓ Region: paired regions for DR (East US 2 + Central US)
      ✓ Networking: Azure CNI Overlay + private API server + private endpoint
      ✓ Identity: Workload Identity (no stored secrets)
      ✓ Node pools: system pool (3 nodes, Standard_D4s_v5) + 
        user pool (autoscale 3-10, Standard_D8s_v5)
      ✓ Security: Azure Policy + network policies + pod security standards
      ✓ Upgrades: node surge 33%, PDB on all critical workloads
    → Produces IaC checklist + Terraform/Bicep scaffolding
    → Flags: "PCI compliance requires additional controls — 
      see network isolation and encryption-at-rest recommendations"
  ```

- **What Used to Happen** — 3 engineers spend 2 weeks reading docs, debating CNI choices in Slack, writing a design doc, getting it reviewed by the platform architect, discovering 2 anti-patterns in the PR review, reworking, and deploying. Total: 3 weeks, 2 rework cycles.
- **What Happens Now** — 1 engineer, 30 minutes, production-grade configuration aligned with AKS engineering recommendations. The PR passes review on the first try because the skill encoded the same knowledge the reviewer would have checked.

**Slogan:** *Three weeks to thirty minutes. Same quality. Zero anti-patterns.*

**Visual Idea:** A "before/after" timeline — Before: a winding road with detours labeled "Slack debate," "design review," "rework," "another review." After: a straight highway from "requirement" to "production-ready cluster." Same destination, dramatically different journey.

**Speaker Notes:**
> This scenario sells to engineering managers and directors. The 3-weeks-to-30-minutes framing is provocative — acknowledge that some design discussion is valuable, but stress that the *knowledge gap* is what causes the rework cycles. The skill eliminates the gap, so the design discussion can focus on business logic, not "did we pick the right CNI?"

---

### Slide 25: Scenario 2 — 2 AM Incident: Node Failure Diagnosis

**Hook:** The pager goes off. A production node is NotReady. Here's the old way and the new way.

**Key Points:**

- **The Old Way (30-60 minutes):**
  ```
  02:00 — PagerDuty alert: "Node NotReady in aks-prod-eastus2"
  02:03 — Engineer opens laptop, connects to VPN
  02:07 — SSH into bastion, runs kubectl get nodes
  02:10 — kubectl describe node — sees MemoryPressure
  02:15 — Googles "AKS node MemoryPressure" — reads 3 articles
  02:22 — Checks pod resource requests, finds no limits set
  02:28 — Escalates to senior engineer (wakes them up)
  02:35 — Senior suggests: check eviction thresholds, look at DaemonSets
  02:42 — Finds monitoring DaemonSet using 2GB per node uncapped
  02:50 — Applies resource limits, cordons node, drains pods
  02:58 — Node recovers, pods rescheduled
  03:05 — Writes incident report
  Total: 65 minutes, 2 engineers, knowledge in heads only
  ```

- **The New Way (5 minutes):**
  ```
  02:00 — PagerDuty alert: "Node NotReady in aks-prod-eastus2"
  02:01 — Engineer opens terminal:
          az aks agent "why is my node NotReady in aks-prod-eastus2?"
  02:02 — Agent (Skills + MCP):
          → Checks node conditions → MemoryPressure detected
          → Correlates with pod resource usage → monitoring DaemonSet 
            using 2.1GB/node with no limits
          → Checks eviction thresholds → soft eviction at 100Mi triggered
          → Proposes: "Apply memory limit of 1GB to monitoring DaemonSet,
            cordon affected node, drain and uncordon after recovery"
  02:03 — Engineer reviews proposal, approves
  02:04 — Agent executes, verifies node recovery
  02:05 — Agent generates incident summary for the postmortem
  Total: 5 minutes, 1 engineer, knowledge captured in agent interaction
  ```

- **The Multiplier Effect** — The next time this happens (to any engineer on the team), the agent already knows the pattern. The 5 minutes becomes 3 minutes. The knowledge compounds.

**Slogan:** *Two AM. Five minutes. One engineer. The agent never forgets.*

**Visual Idea:** A dramatic split-screen clock — left side: 65 minutes counting up in red, with a stressed engineer icon. Right side: 5 minutes counting up in green, with a calm engineer icon. The agent logo sits between them, connected to the right side.

**Speaker Notes:**
> This is your emotional climax. Everyone in the room has been the 2 AM person. Walk through the old way slowly — let them feel the pain. Then walk through the new way quickly — let them feel the relief. The "wakes up the senior engineer" moment in the old way is the key emotional beat. In the new way, the senior engineer sleeps through the night. That's the ROI.

---

### Slide 26: Scenario 3 — Continuous Optimization: Cost & Performance

**Hook:** The most expensive incidents are the ones that never fire an alert — the slow bleed of over-provisioned clusters.

**Key Points:**

- **The Silent Problem** — 60% of Kubernetes clusters are over-provisioned by 30-50% (Datadog State of Kubernetes 2024). No alert fires. No incident opens. You just pay more every month.

- **The Agent-Driven Optimization Cycle:**
  ```
  Engineer: "Optimize my cluster for cost without impacting reliability."

  Agent (Skills + MCP + Advisor):
    → Calls aks_advisor_recommendation: pulls Cost + Performance recs
    → Calls call_kubectl: kubectl top nodes (checks actual utilization)
    → Calls get_aks_vmss_info: checks current SKU vs. utilization
    → Correlates: 
      "Node pool 'workload' is running 8x Standard_D8s_v5 (8 vCPU, 32GB each)
       but average utilization is 23% CPU, 31% memory.
       
       Recommendations:
       1. Downsize to Standard_D4s_v5 (save ~$1,200/month)
       2. Enable cluster autoscaler: min 4, max 10 (save ~$800/month 
          during off-peak)
       3. Remove 2 unused PersistentVolumes (save ~$45/month)
       
       Total estimated savings: $2,045/month ($24,540/year)
       Risk: Low — current peak utilization fits within recommended sizing"
  ```

- **Recurring Health Checks** — Embed `az aks agent "run a cost optimization review"` in a weekly scheduled task. The agent produces a report, surfaces anomalies, and tracks savings over time. Optimization becomes a *habit*, not a *project*.

**Slogan:** *The most expensive bug is the one that never fires an alert.*

**Visual Idea:** A "hidden cost iceberg" — above the waterline: "Incidents (visible, alert-driven)" with a small dollar sign. Below the waterline (much larger): "Over-Provisioning (invisible, no alerts)" with a massive dollar sign. The agent dives below the waterline.

**Speaker Notes:**
> This scenario sells to finance and leadership. The $24,540/year number is conservative for a single cluster — multiply by the number of clusters in the audience's environment. The recurring health check point is the strategic anchor: "This isn't a one-time audit. The agent does this every week, automatically." That's how you turn cost optimization from a quarterly fire-drill into continuous improvement.

---

### Slide 27: Scenario 4 — Multi-Cluster Fleet Management

**Hook:** You don't have one cluster. You have fifteen. The agent manages them as a fleet.

**Key Points:**

- **The Fleet Challenge** — Enterprise environments have 5-50+ clusters: production, staging, dev, per-region, per-team. Keeping them consistent (versions, policies, configurations) is a full-time job. Keeping them *all healthy* is impossible with manual checks.

- **The Agent-Driven Fleet Workflow:**
  ```
  Engineer: "Give me a fleet health report across all my clusters."

  Agent (Skills + MCP with az_fleet):
    → Lists all Fleet members across subscriptions
    → For each cluster: checks version, node health, advisor recommendations
    → Produces fleet-wide report:

    "Fleet Summary (15 clusters, 3 regions):
     ✅ 11 clusters: healthy, current version, no recommendations
     ⚠️ 3 clusters: running v1.29 (EOL in 30 days)
        → aks-dev-eastus2, aks-staging-westus, aks-sandbox-centralus
     🔴 1 cluster: node failure detected
        → aks-prod-westus: 1/8 nodes NotReady (DiskPressure)
     
     Recommended Fleet Actions:
     1. Schedule v1.29 → v1.30 upgrade for 3 non-prod clusters
     2. Investigate disk pressure on aks-prod-westus (see Scenario 2)
     3. 4 clusters have unaddressed Cost advisor recommendations
        (est. savings: $8,200/month)"
  ```

- **Fleet Update Orchestration** — "Upgrade all my non-production clusters to v1.30 in a canary pattern" → the agent uses `az_fleet` update runs and strategies to orchestrate the rollout: dev first, then staging, then pre-prod, with health gates between each stage.

**Slogan:** *Fifteen clusters. One conversation. Fleet-wide intelligence.*

**Visual Idea:** A "fleet dashboard" mockup — grid of 15 cluster cards, each showing name, region, version, health status (green/amber/red). A filter bar at the top. An agent chat panel on the right with the fleet report. Everything connected by MCP lines.

**Speaker Notes:**
> This resonates with platform teams managing multi-cluster environments. The key insight: "You probably run a fleet health review every week manually. It takes 2-3 hours across all clusters. The agent does it in 30 seconds." The canary upgrade orchestration is the enterprise hook — mention Azure Fleet's built-in update strategies and health gates.

---

*This section grounded the entire deck in reality: Day-0 provisioning, 2 AM incidents, cost optimization, and fleet management — the four pillars of Kubernetes operations, all transformed by the Skills + MCP + CLI stack.*

---
---

## Section 7: Resource Hub — Reference & Useful Links

> *"Everything you need to get started — in one place."*

---

### Slide 28: Getting Started — Your First Five Minutes

**Hook:** You've seen the vision. Here's how to have it running in five minutes.

**Key Points:**

- **Step 1: Install AKS Skills (30 seconds)**
  ```bash
  # Option A: GitHub Copilot for Azure extension (recommended)
  # Install from VS Code Extensions marketplace — skills auto-activate

  # Option B: Direct install
  npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-kubernetes
  npx skills add https://github.com/microsoft/github-copilot-for-azure --skill azure-diagnostics
  ```

- **Step 2: Set Up AKS MCP Server (60 seconds)**
  ```
  VS Code → Command Palette → "AKS: Setup AKS MCP Server" → Done.
  ```

- **Step 3: Try Your First Prompt (30 seconds)**
  ```
  "What are the best practice recommendations for a highly reliable AKS cluster?"
  "List all my AKS clusters"
  "Why is my node NotReady?"
  ```

- **Step 4 (Optional): Install Agentic CLI**
  ```bash
  az extension add --name aks-preview
  az aks agent "hello, what can you help me with?"
  ```

- **Step 5 (Optional): Set Up ARO MCP Server**
  ```bash
  git clone https://github.com/sschinna/aro-mcp-server.git
  cd aro-mcp-server
  dotnet build tools/Azure.Mcp.Tools.Aro/src/Azure.Mcp.Tools.Aro.csproj
  # Open workspace in VS Code — .vscode/mcp.json auto-registers
  ```

**Slogan:** *Five minutes to transform how you operate Kubernetes.*

**Visual Idea:** A numbered checklist with estimated time next to each step. A progress bar at the bottom filling up. A "You're operational!" celebration graphic at the end.

**Speaker Notes:**
> End on action. Put this slide up and say: "Open VS Code. Do steps 1 and 2 right now. I'll wait." If the audience is hands-on, give them 2 minutes. The best demo is when the audience runs it themselves. If it's a passive presentation, end with: "You can have this running before your next meeting."

---

### Slide 29: Reference Links & Resources

**Key Resources:**

| Resource | Link | Description |
|---|---|---|
| **AKS Skills Blog Post** | [blog.aks.azure.com](https://blog.aks.azure.com/2026/04/08/agent-skills-for-aks) | Official announcement and walkthrough |
| **AKS Best Practices Skill** | [GitHub - SKILL.md](https://github.com/microsoft/GitHub-Copilot-for-Azure/blob/main/plugin/skills/azure-kubernetes/SKILL.md) | Source file for the best practices skill |
| **AKS Troubleshooting Skill** | [GitHub - azure-diagnostics](https://github.com/microsoft/GitHub-Copilot-for-Azure/tree/main/plugin/skills/azure-diagnostics/aks-troubleshooting) | Source file for the troubleshooting skill |
| **Agent Skills Specification** | [learn.microsoft.com](https://learn.microsoft.com/en-gb/agent-framework/agents/skills?pivots=programming-language-csharp) | Open standard for agent skills |
| **AKS MCP Server (GitHub)** | [github.com/Azure/aks-mcp](https://github.com/Azure/aks-mcp) | Source code, issues, and releases |
| **AKS MCP Blog Post** | [blog.aks.azure.com](https://blog.aks.azure.com/2025/10/22/deploy-mcp-server-aks-workload-identity) | Deployment with Workload Identity |
| **CLI Agent for AKS Blog** | [blog.aks.azure.com](https://blog.aks.azure.com/2025/08/15/cli-agent-for-aks) | Agentic CLI announcement and architecture |
| **CLI Agent Preview Signup** | [aka.ms/cli-agent/signup](https://aka.ms/cli-agent/signup) | Join the limited preview |
| **HolmesGPT (CNCF Sandbox)** | [github.com/robusta-dev/holmesgpt](https://github.com/robusta-dev/holmesgpt) | Open-source agent framework (Microsoft co-maintained) |
| **AKS Extension for VS Code** | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-aks-tools) | One-click MCP server setup |
| **ARO MCP Server** | [github.com/sschinna/aro-mcp-server](https://github.com/sschinna/aro-mcp-server) | ARO MCP server source code |
| **GitHub Copilot for Azure** | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azure-github-copilot) | Skills bundle for Azure |
| **MCP Specification** | [modelcontextprotocol.io](https://modelcontextprotocol.io) | Model Context Protocol standard |
| **Inspektor Gadget** | [inspektor-gadget.io](https://inspektor-gadget.io) | eBPF-powered observability |

**Community & Support:**
- AKS GitHub Issues — for feature requests and bug reports
- Azure Kubernetes Service documentation — official docs
- AKS Community Slack / Discord — peer support
- Azure Support — for production issues

**Slogan:** *Bookmark this page. Share it with your team. Start building.*

**Visual Idea:** A clean, scannable QR code grid — one QR code per major resource, arranged in a 3x4 grid with labels. Audience can scan and open on their phones immediately.

**Speaker Notes:**
> Don't read this slide. Put it up, give the audience 30 seconds to photograph it or scan QR codes, and move to the closing. Say: "Everything you need is on this slide. The repo, the blog posts, the installation guides, and the spec. Share this with your team."

---

### Slide 30: Closing — The Momentum Is Yours

**Hook:** You didn't come here to learn about a CLI. You came here to learn how to stop drowning in operational complexity.

**Key Points:**

- **What You Saw Today:**
  1. **The Problem** — Kubernetes operations don't scale with humans. Cognitive load, knowledge silos, and manual workflows are the real bottlenecks.
  2. **The Skills Layer** — AI-native, composable, open-standard knowledge packages that turn any agent into an AKS/ARO expert.
  3. **The Context Layer** — MCP Servers that give agents live, authenticated, permission-aware access to your actual cluster state.
  4. **The Action Layer** — An Agentic CLI that closes the loop from diagnosis to remediation, with human-in-the-loop safety.
  5. **The Pattern** — This architecture is portable across AKS, ARO, and any MCP-compatible platform. Your operational intelligence is an asset, not a silo.

- **The Call to Action:**
  - **This week:** Install AKS Skills and the MCP Server. Run your first diagnostic prompt.
  - **This month:** Encode your top 3 internal runbooks as custom skills.
  - **This quarter:** Deploy the MCP Server in-cluster for your platform team. Measure MTTR before and after.
  - **This year:** Build a fleet-wide intelligence layer that makes every engineer as effective as your best.

**Closing Line:** *Leading organizations aren't just looking for better clusters. They're building the brainpower to operate them autonomously. Today, you saw the blueprint. Now, master your momentum.*

**Visual Idea:** The opening quote returns on screen, now with the full architecture diagram behind it — Skills + MCP + CLI, connected across AKS and ARO. A single call-to-action: "Start today. Five minutes."

**Speaker Notes:**
> Slow down for the closing. Revisit the opening quote — it should now carry more weight after 30 slides of substance. The call-to-action is deliberately time-boxed: "this week, this month, this quarter, this year." Give the audience a roadmap, not just inspiration. End by saying: "The tools are ready. The architecture is proven. The only question is: will you start today?" Pause. Thank the audience. Open for Q&A.
