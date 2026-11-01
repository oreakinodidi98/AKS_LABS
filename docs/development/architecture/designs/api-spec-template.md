---
title: "API proposal: feature name"
description: Reusable template for public interfaces, caller behavior, compatibility, and validation.
---

> Audience: API contributors, consumers, and reviewers

Copy this template to `api.md` in the feature design folder, or use the
repository's equivalent location. Link it from the feature design. Keep one
proposal for related interface changes; split only when distinct API areas
need separate treatment.

Follow the repository's approval process. The
[feature authoring guide](../../guides/authoring-a-new-feature.md) provides a
workflow you can adapt. Short declarations, examples, and bullets are welcome.
Mark irrelevant sections "Not applicable" with a reason, and keep unresolved
decisions visible for review.

- Tracking item: Link the issue, ticket, or other agreed record.
- Feature design: Link the associated design.
- Status: Proposed
- Reviewers: People responsible for API approval.

Cover the public interfaces the project actually exposes, such as library
methods, service endpoints, command-line interfaces, events, or extension
contracts. Do not assume particular languages, SDKs, or transport protocols.
Declarative configuration and infrastructure interfaces can use the same
questions where they define a contract for consumers. If the feature changes
no public interface, record that in its design; a separate API proposal is
not needed unless the repository requires one.
Keep architecture, target support, shared behavior, and recovery decisions in
the feature design and link them here.

## Caller scenarios

- Link the feature design's usage scenarios rather than restating the problem.
- Show a short example for each affected public interface: input or call,
  result, and cleanup where needed.
- If an existing interface supports the feature without changes, show how.
- Add a second example only when it uses the interface differently.
- Use a small diagram when call order, state, or ownership needs clarification.
  Link an existing design diagram if it already covers the caller's needs.

## Proposed interface

### Design guidance

- Follow existing naming, types, construction, error, and documentation patterns.
- When multiple clients or language bindings exist, provide equivalent supported
  behavior through idiomatic interfaces. Explain intentional differences.
- Keep domain inputs separate from per-call controls, such as cancellation or
  timeout, when that matches the project's conventions.
- Prefer an existing public entry point over a parallel feature-specific path
  unless a separate interface is necessary.

### Declarations and contracts

For each affected interface:

- Name its entry point, such as a module, namespace, package, endpoint, command,
  or event name. State its version if the project versions that interface.
- Show the proposed contract in a code block using its language or schema.
  Include imports, parameters, optional values, defaults, return types, and
  new or changed public types as applicable.
- For service interfaces, specify methods, routes, headers, request and response
  shapes, status codes, authentication, and relevant content types.
- For command-line interfaces, specify invocation syntax, options, input and
  output formats, exit statuses, and stdout/stderr behavior.
- For events or asynchronous messages, specify payloads, delivery guarantees,
  ordering, acknowledgment, and versioning where relevant.
- For declarative interfaces, specify accepted fields, validation, defaults,
  reconciliation behavior, and how changes or deletion affect existing state.
- Make synchronous or asynchronous behavior explicit. Show progress, streaming,
  timeout, and cancellation contracts when supported.

For example, a hypothetical library interface could be:

```typescript
export interface ItemStatusOptions {
  signal?: AbortSignal;
}

export interface ItemStatus {
  id: string;
  state: "pending" | "ready" | "failed";
}

export declare function getItemStatus(
  itemId: string,
  options?: ItemStatusOptions,
): Promise<ItemStatus>;
```

This is a declaration example, not a required language or API. Use the actual
project's interface format. Do not include implementation bodies; place caller
usage examples in the previous section.

## Inputs, results, and errors

For each new or changed input:

- What does it control, and what values are allowed? Specify measurement units.
- Is it required? If not, what default applies?
- What happens when it is omitted, empty, or null? Mark cases the contract cannot
  represent "Not applicable" and explain briefly.
- Which values are rejected, at which boundary, and with what error?

For each new or changed result:

- What does each field, variant, status, or exit code mean?
- What does the caller receive on failure, timeout, or cancellation?
- Must the caller close, acknowledge, dispose of, or release anything? Show how.
  If the interface owns no resources, state that rather than inventing cleanup.
- How are partial results and cleanup failures represented without hiding the
  original error?
- Which identifiers or state APIs support retry and recovery? Link recovery
  rules from the feature design and show the relevant calls in the examples.
- If capability or availability discovery changes, how does it distinguish
  supported, unsupported, and undetermined states?

Link shared allowed values and defaults from the feature design. Describe only
interface-specific representations and behavior here. If clients or language
bindings differ, name the affected interfaces and explain why.

## Compatibility and mapping

- Will existing callers continue to compile and behave the same? Identify source,
  binary, wire, and behavioral breaks as applicable.
- Follow the project's versioning and deprecation policy. Explain any new version,
  transition period, migration steps, or compatibility adapter.
- Map public inputs and results to internal contracts, configuration, storage,
  or transport fields where relevant. Name the source of truth and version;
  link shared contract changes rather than redefining them.
- Explain how "not provided" differs from an explicitly supplied value.
- Link target support and permission decisions from the feature design. Name
  the public errors that expose unsupported combinations or denied operations.
- If no mapping or versioning applies, state that with a reason.

## Validation and documentation

- Link the feature design's validation plan.
- Name interface-specific tests for declarations, serialization, mapping, error
  conversion, compatibility, and caller-owned resource disposal as applicable.
- Exercise public entry points and representative consumer usage, not only
  internal helpers. Identify where these tests run in automation.
- List reference documentation, examples, migration guides, and release notes
  that need updates. Link this list from the feature design.

## Open questions

List unresolved API decisions and their owners, or write "None". Resolve material
questions before the affected interface is implemented.

## Review checklist

- [ ] Examples demonstrate useful caller tasks and correct ownership.
- [ ] Entry points and concrete contracts are specified.
- [ ] Defaults, optional values, errors, timeouts, and cancellation are explicit.
- [ ] Affected interfaces provide the agreed behavior through established patterns.
- [ ] Intentional client or language differences are explained.
- [ ] Support and recovery decisions are linked and exposed consistently.
- [ ] Compatibility, mapping, and any migration requirements are addressed.
- [ ] Public interface tests and consumer documentation updates are planned.
- [ ] Shared design details are linked, not repeated.
- [ ] API approval is recorded according to the repository's process.
