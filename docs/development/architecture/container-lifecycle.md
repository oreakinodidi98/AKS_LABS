---
title: Resource lifecycle architecture
description: Repository-neutral guidance for resource creation, use, cleanup, compatibility, and recovery.
---

> Audience: Contributors, API designers, and operators

Apply lifecycle guidance to resources the project actually manages, such as
containers, sessions, jobs, connections, environments, or remote service objects.
Projects without managed resources can mark these concerns not applicable.
The filename is retained for existing references; the model is not
container-specific.

The operations, states, and contracts below are illustrative, not claims about
an implemented API. Follow the repository's established architecture and define
the supported behavior in the affected feature design and API reference.

## Purpose and scope

A resource used across several operations needs explicit ownership, identity,
state transitions, and recovery rules. An API that creates, uses, and removes a
resource in one call has different caller responsibilities from an API that
keeps the resource available between calls.

Support either model, or both, only where the underlying implementation provides
meaningful behavior. Do not turn an application or library into a persistent
orchestrator unless the project actually requires that responsibility.

Define these decisions before implementation:

- The user problem and meaningful usage scenarios.
- Whether state is transient or persistent and where it is stored.
- Which component owns resources and which caller or operator releases them.
- Supported operations, platforms, providers, and prerequisites.
- Compatibility, security, validation, and recovery requirements.

Use the [feature spec template](designs/feature-spec-template.md) and
[API proposal template](designs/api-spec-template.md) for feature-specific decisions.

## Design principles

- Reuse the normal implementation path and existing domain types where they fit.
  Separate new behavior from prerequisite refactoring.

- Expose supported behavior honestly. An unsupported operation should return an
  explicit error, not silently succeed. A documented no-op is appropriate only
  when it satisfies the operation's actual contract.

- Assign structural validation to input boundaries and semantic checks to the
  owning component. Client-side checks improve feedback but do not replace
  runtime validation or authorization.

- Preserve field presence through parsing and adaptation. Apply defaults where
  the project owns their meaning rather than silently inventing them in adapters.

- Treat identity, routing, authorization, availability, and state as separate
  concerns. A valid identifier does not prove a resource exists or grant access.

- Make platform or provider differences explicit. Do not manufacture parity by
  weakening restrictions or claiming capabilities that are unavailable.

## Lifecycle model

Map the project's native states and operations before choosing public names.
The following five-stage model suits some reusable resources, but is not required:

| Operation  | Example starting state | Example resulting state | Purpose                          |
| ---------- | ---------------------- | ----------------------- | -------------------------------- |
| Create     | Absent                 | Allocated               | Allocate a resource and identity |
| Activate   | Allocated              | Ready                   | Make the resource available      |
| Use        | Ready                  | Ready                   | Perform work with the resource   |
| Deactivate | Ready                  | Allocated               | Stop use while retaining state   |
| Delete     | Allocated              | Absent                  | Release the resource             |

Some projects combine creation and activation, allow deletion from any state,
or need states such as pending, failed, suspended, or deleting. Document these
differences rather than forcing them into the example.

For each operation, specify:

- Valid starting states, preconditions, and resulting states.
- Whether completion means accepted, started, ready, or fully finished.
- Persistent state retained or discarded.
- Whether repeated calls succeed, return existing state, or fail.
- Whether concurrent calls are allowed, serialized, or rejected.
- Timeout, cancellation, and partial-failure behavior.
- Whether a failed operation leaves the resource usable.

State changes must be checked by the authoritative owner. A client's cached
state can become stale between validation and execution.

## Automatic and manual ownership

An automatic create-and-use operation can compose the relevant lifecycle stages
and perform cleanup before returning. A manual lifecycle API returns an identity
or handle that the caller retains for later operations.

If both models exist:

- Share validation, domain behavior, and cleanup helpers where appropriate.
- Document differences in resource lifetime, persistence, and failure handling.
- Define whether cancellation or caller exit ends only the current operation or
  also removes the resource.
- Explain whether live handles, background work, or remote resources outlive the
  API call. Asynchronous execution alone does not imply durable detachment.
- Do not let automatic cleanup remove a resource owned by another caller.

## Identity and scope

Use the project's existing identity or handle conventions. An opaque identifier
can decouple callers from implementation details; a local handle can provide
automatic disposal. Neither model is universally preferable.

Document:

- Who creates the identity and whether callers must persist it.
- Its scope: process, machine, account, tenant, region, or service.
- When it becomes valid and when it expires or becomes stale.
- Whether it survives restart, upgrade, migration, or provider changes.
- How malformed, unknown, expired, and inaccessible identities are reported.
- How routing determines the owning implementation.
- How an operation verifies identity ownership and permissions at runtime.

Do not embed credentials or personal data in identifiers. If identifiers include
a provider prefix or format version, treat that format as a compatibility
contract. Callers should not parse opaque content unless explicitly supported.
Compile-time brands or wrapper types can reduce mistakes, but are not security
boundaries.

Creation can fail after allocation but before the caller receives an identity.
Choose a recovery mechanism appropriate to the project, such as an idempotency
key, request-status lookup, owner-scoped listing, lease, or operator cleanup.
Do not assume "no identifier returned" means "no resource created".

## Public interfaces and request contracts

Expose lifecycle behavior through the interfaces the project supports: library
methods, service endpoints, commands, messages, or declarative configuration.
Use idiomatic names and types rather than requiring identical syntax across clients.

For each interface, specify:

- Entry point, operation, input shape, result shape, and version where applicable.
- Required resource identity and any creation-time provider selection.
- Allowed configuration per operation, including omitted, empty, and null values.
- Per-call controls such as timeout or cancellation.
- Authentication, authorization, and supported targets.
- Caller-owned result handles and how to release them.

The following language-neutral request illustrates a possible shape:

```json
{
  "operation": "use",
  "resourceId": "opaque-resource-token",
  "input": {
    "task": "example-task"
  },
  "options": {
    "timeoutMs": 5000
  }
}
```

These field names are examples, not a required schema. Follow the project's
contract format, naming, and version policy.

Use operation-specific contracts when they prevent invalid combinations.
Reject fields that are unsupported or inappropriate for an operation according
to the contract's compatibility policy. Keep extension points intentional,
bounded, validated, and documented.

Locate the source of truth for generated schemas or bindings and regenerate them
with existing tools. External serialized inputs and direct typed calls should
converge on the same domain behavior without requiring unnecessary serialization.

## Results, streams, and errors

Distinguish successful API execution from the outcome of the work it performs.
A completed job can have a non-success workload result even when the API
successfully observed its completion.

Define separate representations for:

- Operation success and returned resource metadata.
- Pending or accepted work and how to observe completion.
- Workload output, status, and completion result.
- Invalid input, denied access, unsupported capability, or dependency failure.
- Timeout, cancellation, partial completion, and cleanup failure.

Reuse the repository's stable error model. Examples of useful categories are
invalid request, invalid identity, resource not found, invalid state, conflict,
permission denied, unavailable dependency, and unsupported operation. These
categories are not a mandatory enum.

Include actionable, sanitized context such as the operation, retry guidance,
resource state, and recovery identifiers. Report both the primary failure and
any cleanup failure without replacing one with the other.

For streaming or command-line interfaces:

- Keep machine-readable results separate from diagnostics and workload output.
- Specify stdout, stderr, exit statuses, and any separate control channel.
- Do not append structured results to arbitrary output unless framing is defined.
- Define ordering, buffering limits, backpressure, truncation, and cancellation.
- Explain how callers observe the final status and release stream handles.

## Implementation boundaries

Adapt the following responsibilities to existing components rather than adding
new layers solely to match this list:

| Responsibility             | Typical owner                                           |
| -------------------------- | ------------------------------------------------------- |
| Public input and feedback  | Client or public API boundary                           |
| Contract parsing           | Transport or configuration adapter                      |
| Routing and authorization  | Service or application dispatcher                       |
| Defaults and domain rules  | Owning domain component                                 |
| Native resource operations | Provider, runtime, storage layer, or service adapter    |
| Durable state and recovery | Explicitly designated resource owner                    |
| Diagnostics and telemetry  | Shared instrumentation and configured sinks             |

Keep parsing separate from enforcement. A schema that accepts a restriction does
not prove the implementation can enforce it. Check capabilities and permissions
before allocating resources wherever possible.

Reuse established interfaces, shared execution settings, and adapters. Introduce
operation-specific types when they express a real invariant or new behavior,
not merely to duplicate an existing model under another name.

## Configuration and capability checks

For each implementation and operation, document which settings are applied,
rejected, inherited, or fixed. Avoid an ambiguous "ignored" classification for
security-sensitive input.

| Setting             | Creation behavior     | Later-operation behavior    |
| ------------------- | --------------------- | --------------------------- |
| Example access rule | Validated and applied | Inherited; changes rejected |
| Example task input  | Not applicable        | Validated for use           |

Describe effective defaults, allowed updates, and when state must be recreated.
If an implementation cannot enforce a requested restriction, reject it with an
actionable error. Do not substitute a weaker restriction without an explicitly
supported and authorized contract.

Availability checks should distinguish:

- Implemented and available.
- Implemented but unavailable in the current environment.
- Unsupported by the selected implementation.
- Availability cannot be determined.

A discovery result is a snapshot, not a guarantee that the next operation will
succeed. Runtime checks remain necessary.

## Adding an implementation or provider

Follow the [feature authoring guide](../guides/authoring-a-new-feature.md).
For each new implementation:

1. Agree on supported operations, ownership, and target environments.
2. Map the native lifecycle to the public contract and document exclusions.
3. Reuse the existing extension mechanism and register routing where needed.
4. Define typed configuration and results using established patterns.
5. Implement structural and semantic validation, authorization, and enforcement.
6. Map dependency errors to the public error model without hiding context.
7. Implement cleanup and recovery with explicit partial-failure behavior.
8. Update schemas, generated artifacts, public references, and operational guidance.
9. Add behavior tests and wire them into the appropriate automated jobs.

Do not require a plugin framework or registry if the project has no need for one.

## Failure and recovery

Failures can leave state uncertain even when the API is synchronous. A timeout
or lost response does not prove that a remote operation failed to complete.

| Failure point | Possible remaining state            | Recovery considerations                      |
| ------------- | ----------------------------------- | -------------------------------------------- |
| Creation      | Absent, partial, or fully allocated | Find or reconcile before creating again      |
| Activation    | Inactive, partial, or ready         | Query authoritative state; retry or clean up |
| Use           | Ready, busy, changed, or unhealthy  | Check work outcome and retry safety          |
| Deactivation  | Active or inactive                  | Verify state and owned work before retry     |
| Deletion      | Present, partial, or absent         | Reconcile leftovers and verify removal       |

These are possibilities, not guaranteed states. Define implementation-specific
behavior and available inspection or recovery operations.

Handle caller exit and dependency loss explicitly. Persist recovery identifiers
before later operations when caller persistence is required. For allocations
whose response was lost, provide the agreed orphan-recovery mechanism.

Document idempotency, concurrency control, retry limits, and backoff. Use leases,
transactions, reconciliation, or locks only where required by the actual
consistency model. Do not promise exactly-once effects or transactional cleanup
unless the underlying system provides them.

Manual recovery instructions must identify resources safely, verify ownership,
and avoid deleting unrelated state. Report remaining work when cleanup is
best-effort or cannot be verified.

## Observability

Record bounded operation outcomes, duration, state transitions, and cleanup
results using the [telemetry guidance](telemetry.md).
Distinguish requested actions from confirmed results and unknown state.
Telemetry does not replace a public result or prove that cleanup occurred.

Use suitable correlation identifiers across operations while keeping resource
identities and sensitive input out of exported data unless explicitly approved.
Provide operators with recovery information through the appropriate protected
diagnostic channel.

## Validation plan

Verify observable behavior through relevant public entry points:

- A complete supported lifecycle and repeated use of retained state.
- Automatic ownership and manual ownership, if both are offered.
- Invalid transitions, malformed identities, stale identities, and denied access.
- Unsupported operations, missing dependencies, and unavailable environments.
- Defaults, omitted or empty values, and operation-specific configuration.
- Concurrency, repeated requests, and documented idempotency.
- Cancellation, timeout, caller exit, and lost responses.
- Partial allocation, failed cleanup, recovery, and a subsequent safe attempt.
- Streaming completion, output integrity, and handle disposal where applicable.
- Compatibility across supported clients, versions, and deployment modes.

Use unit tests for isolated rules and integration tests for dependency and
resource behavior. Name the required environments and automated jobs. Record
actual results and limitations; do not imply support from tests that never run.

## Rollout, versioning, and bounds

Follow the project's release and compatibility policies. Public interface
stability, implementation maturity, schema publication, runtime authorization,
and environment availability are separate decisions.

Document experimental restrictions and promotion criteria where used. Preserve
supported versions and persisted identities, or provide an explicit migration.
Coordinate contract, implementation, client, documentation, and rollout changes
according to their actual dependencies.

State whether features such as durable background work, cross-machine identity,
snapshots, suspension, resource-wide expiry, or extended metadata are supported,
deferred, or not applicable. Do not add them without a concrete requirement.
