---
title: "Feature design: feature name"
description: Reusable template for proposing feature behavior, architecture, validation, and delivery.
---

> Audience: Contributors and reviewers

Copy this template into the repository's design location. A suggested layout is
`<work-item-id>-<feature-name>/README.md`, with supporting API proposals and
diagrams in the same folder. Use the repository's naming conventions instead
when they differ.

Use the questions to guide discussion, not to require a finished design before
review. Short bullets and yes/no answers are enough when they explain the
decision. Mark irrelevant sections "Not applicable" with a short reason, and
link existing context rather than repeating it. Keep the status Proposed until
the designated reviewers approve the design.

- Status: Proposed
- Tracking item: Link the issue, ticket, or other agreed record.
- Contributors: Names or account identifiers.
- Reviewers: People responsible for design approval.
- Implementation changes: Links, or "Not started".

Describe feature behavior, architecture, contracts, and recovery here. When
public interfaces change, use the [API proposal template](api-spec-template.md)
for declarations and caller examples, and link the completed proposal.

## Problem and scope

- Who has the problem, and what can they not do today?
- How does this feature solve that problem?
- Give one or two distinct usage scenarios with concrete inputs, expected
  outcomes, and cleanup where needed. Do not invent an additional scenario
  when only one is meaningful.
- What is out of scope?
- Which existing behavior must remain unchanged?

## Proposed behavior

- What does the user or caller provide, and what result do they receive?
- Which operations, workflows, or state transitions change?
- What are the defaults? What happens when a value is omitted, empty, or null?
- What happens for invalid or unsupported requests?
- Are operations synchronous, asynchronous, streamed, or long-running?
  Describe ordering, progress, completion, and cancellation where relevant.
- Does the feature create or modify persistent state? Describe valid operation
  order and what persists between calls or sessions.

## Applicability and availability

Consider the components, platforms, clients, deployment modes, or integrations
that the repository supports. Do not require additional implementations merely
to make all targets identical.

| Target | Planned support and reason | Prerequisites and checks | How availability is reported |
| ------ | -------------------------- | ------------------------ | ---------------------------- |
| Name   | Yes / No / Not applicable  | Versions or capabilities | Result, error, or documentation |

- Can a target otherwise work but lack this feature? How is that detected?
- Are there optional dependencies, feature flags, permissions, or configuration
  requirements? Describe defaults and how unsupported combinations are rejected.
- Does this change experimental or supported status? Explain the rollout and
  any restrictions.
- If the project has only one target, state that and describe its prerequisites.

## Architecture and security

- Which existing components change, and what is each responsible for?
- Trace the normal request or data flow and explain where the new behavior
  belongs. Reuse existing paths and shared helpers where appropriate.
- Use a small sequence, data-flow, or state diagram when clearer than text.
  Follow the repository's supported diagram format.
- Does this change permissions, isolation, trust boundaries, or data access?
  Explain enforcement, validation, and handling of sensitive data.
- Does this introduce a dependency, module, service, or substantial refactor?
  Explain why it is needed and how it fits existing architecture rules.
- What is the main alternative, and why was it not chosen?

## Contracts and compatibility

- Which APIs, schemas, configuration formats, events, or stored data change?
  Identify their sources of truth and any generated artifacts.
- Will existing consumers continue to work? Identify source, binary, wire,
  configuration, data, and behavioral compatibility concerns as applicable.
- Describe migrations, deprecations, versioning, and rollback requirements.
  Follow the project's compatibility policy rather than assuming a new version
  is always required.
- Link the API proposal for public interface details instead of duplicating it.

## Resource ownership and failure recovery

Name the systems involved and distinguish the responsibilities of the
application, dependencies, operators, and callers. Cover local and remote
resources when applicable.

- Who owns and releases resources at each stage? Consider connections,
  processes, storage, transactions, locks, subscriptions, and temporary files.
- If an operation fails, times out, or is cancelled partway through, what state
  remains? Describe cleanup, rollback, and recovery responsibilities.
- What happens on process exit, loss of connectivity, or dependency failure?
- If cleanup or rollback also fails, how are both failures reported? How can
  users identify leftover state and retry or perform manual recovery?
- Are retries safe? Explain idempotency, duplicate prevention, concurrency,
  and how partial or leftover state affects a subsequent attempt.
- Can a partially changed resource still be used? Explain how its state is
  determined and when it must be repaired, replaced, or removed.

## Acceptance criteria and validation plan

- List observable pass/fail conditions that prove the feature works.
- For each scenario, state the input or action and the exact result asserted.
  Name an existing test to extend or identify a proposed test.
- Cover relevant defaults, omitted or empty values, invalid inputs, unsupported
  targets, permissions, errors, cancellation, and recovery.
- Test affected public entry points and feature interactions, not only internal
  implementation details.
- Identify test environments, required versions or capabilities, and the
  automated workflow or job that will run each scenario.
- Include performance, accessibility, reliability, and security checks when
  relevant, with measurable thresholds rather than subjective claims.
- Explain any removed or replaced checks and how coverage is preserved.
  Record limitations and scenarios that cannot be automated.

Keep test implementations out of the spec. Report actual results and anything
not run in the implementation review.

## Delivery and documentation

- List implementation stages and their actual dependencies. Split large changes
  into buildable, reviewable slices that preserve existing behavior.
- Describe rollout, feature flags, migrations, monitoring, and rollback where
  needed. Name the responsible owners.
- Which user guides, references, examples, and operational instructions change?
  Link API-specific updates from the API proposal.
- Link supporting documents in this folder or the repository's design location.

## Open questions

What decisions remain, and who will resolve them? Write "None" if there are none.
Resolve questions that materially affect implementation before approval.

## Review checklist

- [ ] Scope, contributors, and approval expectations are agreed.
- [ ] Meaningful usage scenarios, non-goals, defaults, and failure behavior are clear.
- [ ] Relevant targets and prerequisites are considered; exclusions are explained.
- [ ] Operation order, state changes, and availability behavior are explicit.
- [ ] Ownership, partial failure, cleanup, retries, and recovery are addressed.
- [ ] Security, compatibility, and migration requirements are addressed.
- [ ] An API proposal is linked when public interfaces change.
- [ ] Acceptance criteria and automated validation cover observable behavior.
- [ ] Delivery, rollout, and documentation changes are scoped.
- [ ] Shared details are linked, not repeated; material questions are resolved.
- [ ] Design approval is recorded according to the repository's process.
