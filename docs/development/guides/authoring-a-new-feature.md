---
title: Adding a new feature
description: Repository-neutral workflow for discussing, designing, implementing, and validating features.
---

> Audience: Contributors and maintainers

Start with a problem or a rough idea; a complete design is not needed to begin
the conversation. Agree on scope and important design decisions before investing
in implementation.

Apply this workflow to the repository's actual components, whether they are
applications, services, libraries, tools, infrastructure, or documentation.
Follow the repository's contribution, architecture, security, and review rules
where provided. Use its work tracker, terminology, documentation locations,
and approval conventions rather than assuming specific tools or labels.

| Stage                         | Next step                                                   |
| ----------------------------- | ----------------------------------------------------------- |
| You have a feature idea       | [Open or find a tracking item](#1-start-with-a-tracking-item) |
| Scope and ownership are agreed | [Agree on the design](#2-agree-on-the-design)               |
| Required design review is complete | [Implement the design](#3-implement-the-agreed-design)  |

## 1. Start with a tracking item

Find or create an issue, ticket, or other record describing:

- The problem, affected users, and desired outcome.
- Concrete use cases and relevant constraints.
- Related work and known alternatives.
- Whether you intend to contribute the implementation.

Maintainers or designated reviewers should record the agreed scope, contributor,
and next step. Acceptance of an idea is not a release commitment or completed
design review. Use the same record to discuss material scope or ownership changes.

Labels such as `feature-accepted` can help if the repository uses them, but are
not required. A clear recorded decision is more important than a label name.

For security reports, follow the repository's private disclosure process rather
than opening a public issue. If the process is unclear, contact the maintainers
privately before sharing sensitive details.

## 2. Agree on the design

### Decide whether a spec is needed

Follow the repository's requirements and scale design review to the risk.
A separate spec is usually appropriate for:

- New or changed public interfaces or shared contracts.
- Changes to permissions, security boundaries, or policy enforcement.
- Data migrations or significant compatibility changes.
- New platforms, integrations, services, or major dependencies.
- Substantial refactors or changes spanning multiple components.

These considerations apply regardless of whether the tracking item is called a
feature, bug, or task. Small, low-risk changes may use an approach recorded in
the tracking item rather than a separate spec, if the repository allows it.
Agree with reviewers on what needs approval.

### Write the spec

Use the [feature spec template](../architecture/designs/feature-spec-template.md)
and the repository's design location. One possible layout is:

```text
<design-location>/<work-item-id>-<feature-name>/
    README.md
    api.md
```

For public interface changes, use the
[API proposal template](../architecture/designs/api-spec-template.md).
Keep shared behavior and architecture in the feature design and declarations
and caller examples in the API proposal. Link the documents and tracking item.
Review related designs together where practical.

To keep human and AI-assisted drafts useful:

- Use concise bullets, declarations, and concrete examples.
- Explain decisions, changed behavior, and risks.
- Mark irrelevant sections "Not applicable" with a reason.
- Include one or two meaningful usage scenarios, not repeated equivalents.
- Consider supported platforms, components, and clients; explain exclusions.
- Link shared details instead of duplicating them.
- Use small diagrams in a format the repository supports when they clarify
  interactions, data flow, state, or ownership.
- Keep unresolved decisions visible and identify who will resolve them.

### Complete design review

Record scope acceptance, design approval, and API approval where applicable.
Use the project's statuses or labels; do not introduce approval gates solely
to match this guide.

Keep a proposed design marked Proposed until approved. If the repository
requires specs to merge before implementation, complete that step first.
Otherwise, follow its review sequence and agree on when implementation can start.

If implementation reveals a material design change, return to the discussion
and update the design before implementing the affected work. Unaffected work
that still follows the agreed design can continue.

## 3. Implement the agreed design

Link the tracking item and approved design in the implementation review. Open a
draft pull request or equivalent change request when early collaboration helps.
Follow the repository's branch, commit, and review-history conventions.

### Choose the layers to change

Trace the feature through each affected layer. Not every project has every layer,
and not every feature needs changes in all of them.

| If the feature changes          | Relevant work                                             |
| ------------------------------- | --------------------------------------------------------- |
| Inputs, schemas, or configuration | Update source contracts, validation, adapters, and fixtures. |
| Domain behavior or policy       | Implement behavior and enforcement in the owning component. |
| Public interfaces or clients    | Update public types, mapping, errors, examples, and tests. |
| Persistence or data exchange    | Plan migrations, compatibility, recovery, and rollback.   |
| Deployment or runtime support   | Update configuration, prerequisites, availability checks, and operations. |
| User interactions              | Update affected workflows, accessibility, feedback, and UI tests. |

Locate the source of truth for generated files and use the repository's
generation tools rather than editing generated output by hand. Adding a schema
field or client property does not implement its underlying behavior.

Keep validation, defaults, authorization, and enforcement in their established
owners. Do not silently accept unsupported input or report success when a required
restriction cannot be enforced. Follow the project's feature-flag and release
policy before exposing experimental or incomplete behavior.

### Plan reviewable changes

Split large work into buildable, reviewable slices. Separate prerequisite
refactoring from behavior changes when that makes review clearer, while preserving
existing behavior.

Order changes by actual dependencies, not a fixed technology-specific sequence.
For example, a service change may need a compatible contract and implementation
before client exposure; a UI feature may need no new contract at all.

For each slice, identify:

- The behavior delivered and affected components.
- Prerequisites and compatibility with earlier or later slices.
- Tests and automation needed to verify it.
- Documentation, rollout, migration, and rollback needs.

Do not expose functionality as supported before its implementation and required
validation are ready.

### Find and reuse the existing path

Trace a similar feature from its public entry point through validation, business
logic, persistence or dependencies, error handling, and cleanup. Read relevant
architecture and contributor guidance before editing.

Identify existing helpers, adapters, and test scenarios. Extend the normal path
instead of adding a parallel implementation or special-case bypass. Add an
abstraction only when it solves a concrete need.

### Validate observable behavior

Use the repository's build, lint, type-check, test, and automation commands.
Start with the smallest checks that cover the change and broaden validation when
risk or targeted results justify it.

- Assert exact outcomes for the agreed acceptance scenarios.
- Add regression coverage for changed or previously broken behavior.
- Cover defaults, invalid or unsupported input, permissions, failure, timeout,
  cancellation, and recovery where relevant.
- Test affected public entry points and interactions, not only internal helpers.
- Use unit tests for isolated logic and integration or end-to-end tests for
  behavior that crosses boundaries.
- Exercise relevant clients, platforms, deployment modes, and optional features.
  Include serialization, packaging, or compilation-mode checks when affected.
- Wire new automated scenarios into the appropriate workflow or job.
- Record required test environments, actual commands and results, and anything
  not run. Do not present planned coverage as verified evidence.

Use the [diagnostics guide](diagnostics.md) when a failure needs investigation.
Documentation-only changes need no runtime tests unless the repository has
documentation checks.

### Update documentation and plan rollout

Update the canonical user guides, references, examples, and operational
instructions affected by the feature. Describe supported behavior and usage,
not implementation history.

For deployed or distributed changes, document feature flags, monitoring,
migrations, version compatibility, and rollback where applicable. Identify who
owns rollout and post-release verification.

## Finish the feature

Keep the tracking item open until the agreed implementation, validation, and
documentation are complete. Intermediate design and implementation changes
should use non-closing references according to the tracker.

Only the final change should close the item when all agreed work is complete;
otherwise, leave closure to the responsible maintainer. Record deferred work
explicitly rather than treating it as delivered.
