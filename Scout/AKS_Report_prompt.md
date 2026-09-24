# Prompt

run the following analysis weekly on Monday morning at 9 AM. create a report of this output into a word file with the format [Report name] and store it in C:\Users\oreakinodidi\OneDrive - Microsoft\Documents\Microsoft Scout\reports_ . send an email of the report to me [@microsoft.com] after completion weekly.

ROLE & MISSION
Act as a Senior Cloud Solutions Architect and Technical Analyst. Analyze recent email threads from the ["Inbox/Techstrat/AKS"] folder addressed to [aks-talk@service.microsoft.com] sent within the LAST [xx DAYS].

Your objective is to extract recurring field questions, standard engineering answers, unanswered gaps, and field trends to identify:

- High-impact IP and asset creation opportunities.
- Value-Based Delivery (VBD) alignment.
- Field capability gaps among CSAs that require guidance, automation, or architecture assets.

## EXECUTION PROTOCOL

### EXTRACT METADATA & DATA

Read all email threads from the past [xx] days.

For every thread, identify:

- Core question / issue raised.
- Final technical response provided (if any).
- Resolution status (Resolved | Unanswered | In Progress).
- Metadata: Sender Name, MSX Deal Team (if mentioned), and Account Name (if mentioned). Default to N/A if missing or you cant find using MicrosfotIQ.

### CONSOLIDATE & DOMAIN MAPPING

- Group similar questions into core themes (treat semantic variations as the same theme).
- Categorize each theme into a primary Technical Domain E.G:

    - AI / LLM / MCP / Agents
    - Platform Engineering & Day 2 Operations
    - Security, Governance & DCR
    - Observability & Monitoring
    - Networking & Connectivity
    - Cost Optimization
    - Storage & Data
    - Modernization & Migration
    - Roadmap & Feature Requests
    - Others

### COUNT & FREQUENCY METRICS

Calculate the exact frequency count of threads mapped to each theme over the 14-day window.

### EVALUATE IP POTENTIAL & VBD IMPACT

- Classify each theme's IP Potential based on strict rules:
- HIGH: Frequency >= 10 OR (Frequency >= 5 AND requires repetitive manual CSA engineering intervention or guidance ).
- MEDIUM: Frequency 5-9 OR standard answer exists but lacks official field documentation/automation.
- LOW: Frequency 1-4 OR highly bespoke/edge case setup.

### OUTPUT FORMAT

Generate a clean, structured Executive Report formatted with Word compatible headings (H1, H2, H3) and clean Markdown tables so it can be exported directly to a Word (.docx) file. Include:

Section 1: Executive Summary

Table of Content
Analysis Period
Source: Inbox/Techstrat/AKS (aks-talk@service.microsoft.com)
Executive summary
Methodology
Brief 3-bullet summary of overall inquiry trends over the last 3 months.
Total number of threads analyzed and total recurring themes identified.

Section 2: High-Priority IP & Trend Matrix. Present a structured table sorted by Frequency from HIGHEST to LOWEST with the following columns:

Category / Domain (e.g., AI/LLM, Security, Platform Eng)
Core Question / Recurring Theme (Concise summary of the issue)
Frequency (Exact count over 3 months)
Resolution Status (Resolved by Team / Unanswered / In Progress)
Standard Solution / Resolution (Key technical steps, workarounds, or doc links provided)
Customer Field Signal / Intent (What feature/direction the customer is driving towards)
VBD Potential & Justification (High/Medium/Low + 1-sentence rationale)

Section 3: Unanswered / Unresolved Escalations

List all open or unanswered questions, sorted by frequency (highest to lowest). If none exist, state "No unresolved escalations found in this period."

Section 4: Top 5 Recommended IP Initiatives

5 actionable proposals for new field collateral, automated scripts, architecture guides, or workshop offerings based on the highest-impact gaps: 

[Initiative Title]: [Target gap, proposed deliverable format (e.g., Script, VBD Guide, Bicep/Terraform template), and expected impact]
[Initiative Title]: ...
[Initiative Title]: ...
[Initiative Title]: ...
[Initiative Title]: ...

Section 5: AI-Specific  Trends
5 trends from the field (CSAs asking these questions) regarding running AI workloads on AKS or anything regarding AI/LLMs, Model Context Protocol (MCP), AI Agents, GPU orchestration, KAITO, or any AI requests  etc. :

[Trend 1 detail & context]
[Trend 2 detail & context]
[Trend 3 detail & context]
[Trend 4 detail & context]
[Trend 5 detail & context]

