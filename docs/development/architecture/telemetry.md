---
title: Telemetry and diagnostic architecture
description: Repository-neutral guidance for instrumentation, privacy, collection, correlation, and validation.
---

> Audience: Contributors, maintainers, and operators

Use instrumentation to understand observable behavior, diagnose failures, and
verify operational requirements. Apply the project's privacy, security, retention,
and reliability policies before adding collection.

The architecture and schemas below are examples, not claims that this repository
implements a particular collector, provider, or consent mechanism. Choose tools
that fit the project's runtime and existing instrumentation. Projects with no
runtime telemetry can use only the relevant diagnostic guidance.

## Separate the collection purposes

| Mechanism            | Purpose                                 | Important distinction                         |
| -------------------- | --------------------------------------- | --------------------------------------------- |
| Diagnostic logs      | Investigate implementation behavior     | Local storage can still expose sensitive data |
| Audit records        | Record accountable actions and outcomes | May require durability and integrity controls |
| Metrics              | Track aggregate health and performance  | Labels must have bounded cardinality          |
| Traces               | Follow work across component boundaries | Correlation context requires validation       |
| Usage telemetry      | Understand approved product usage       | Requires its own collection policy            |

Define these mechanisms separately even if they share an implementation.
Enabling one sink must not silently authorize another purpose or destination.
A local file can be forwarded by an agent or attached to a report; "local" does
not mean anonymous, unregulated, or permanently confined to the host.

Diagnostic records are not automatically a compliant security audit trail.
Where audit durability, tamper resistance, or delivery guarantees are required,
design and test those guarantees explicitly.

## Architecture and ownership

Separate domain instrumentation from destination-specific transport:

```text
public operation or internal component
    -> typed event, metric, or span
    -> policy checks and data minimization
    -> serialization and bounded buffering
    -> approved local or remote sink
```

Reuse the project's logging and instrumentation abstractions. Do not add a
parallel path merely for one feature.

Assign responsibility for:

- Event definitions, schema versions, and approved data inventory.
- Instrumentation at authoritative operation boundaries.
- Configuration, consent where required, and administrative restrictions.
- Sanitization, redaction, and correlation.
- Provider initialization, transport, retry, and shutdown.
- Collector access, retention, deletion, and operational monitoring.

Document any external collector or platform agent separately from application
emission. A registered provider does not prove that a consumer is collecting
events, and writing an event does not prove delivery to a remote service.

## Configuration and collection authorization

State the actual defaults for each build, deployment mode, and sink:

- What is enabled, where records go, and whether network transmission occurs.
- Which user, operator, tenant, or administrator can configure collection.
- The approved purpose, data categories, and applicable lawful basis or consent.
- How restrictions, revocation, and disabled collection are enforced.
- How invalid configuration and unavailable sinks are reported.

When explicit consent is required, an operation option, build flag, or
administrator setting must not manufacture it. Administrative policy may further
restrict collection. Missing or invalid required authorization must prevent the
affected collection, not fall back to an enabled state.

Describe consent wording, versioning, localization, accessibility, persistence,
and revocation only where those mechanisms actually exist. Have the responsible
privacy or legal owners approve disclosures before release. Do not infer legal
approval from a license file or copy another project's classifications.

## Data inventory and minimization

Maintain an allow-list of fields for each event and destination. For every field,
record its purpose, type, allowed values, size limit, sensitivity, and retention.
New model fields must not enter exported data automatically.

Prefer bounded categories, numeric outcomes, and aggregate counts. Review any
free-form or caller-controlled data before allowing it into diagnostics.
Do not export credentials, tokens, connection strings, private keys, raw user
identities, command arguments, environment values, request bodies, or workload
output by default.

Additional rules:

- File paths, URLs, query strings, and exception messages can contain secrets.
  Use approved categories or sanitized structural information instead.
- Schema field names may be useful for rejection records, but dynamic map keys
  and field values are not inherently safe.
- An identifier's character set or length does not prove it lacks personal data.
  Track its provenance and approve its use.
- Hashing personal or low-entropy data is not anonymization.
- Debug mode must not bypass destination policy or sensitive-data controls.
- Apply filtering before records enter queues, disk spools, or transport buffers.

For verbose artifacts, derive a minimal typed projection rather than uploading
raw logs, traces, dumps, or documents. Validate versions and reject unsupported
shapes. Keep original diagnostic artifacts in their separately governed channel.

## Event and record contracts

Use established naming and schema conventions. The following conceptual inventory
can guide a project-specific event design:

| Record                 | When emitted                             | Example bounded fields                   |
| ---------------------- | ---------------------------------------- | ---------------------------------------- |
| Operation completed    | Terminal operation outcome is known      | Operation, outcome, duration, status     |
| Input rejected         | Validation or authorization refuses work | Category, approved field name, phase     |
| Dependency unavailable | Required dependency cannot be used       | Component, category, retryability        |
| Configuration applied  | An effective configuration is confirmed  | Version, approved fingerprint, result    |
| Resource cleanup       | Cleanup finishes or fails                | Result, released counts, remaining state |
| Capability unavailable | A required capability is unsupported     | Capability category, target category     |

Separate requested configuration, an attempted change, and confirmed enforcement.
Do not name an event "applied" or "deleted" when only an attempt is known.
Report unknown state explicitly.

An illustrative structured record is:

```json
{
  "event": "operation.completed",
  "schemaVersion": 1,
  "operation": "use",
  "outcome": "success",
  "durationMs": 125,
  "correlationId": "random-operation-token"
}
```

These names and fields are examples. Choose the project's actual schema and
define outcome semantics. Distinguish application failure from the result of
a workload the application successfully ran.

For machine-readable files, specify encoding, framing, schema version, timestamps,
and rotation behavior. If using JSON Lines, serialize one complete escaped JSON
object per line. Consumers should parse fields rather than rely on object key order.
Keep records out of primary output channels whose contracts carry caller results
or arbitrary workload output.

## Correlation and identity

Use the project's existing trace or correlation format where available. Define
operation, session, and resource-lifecycle scopes separately.

- Generate correlation identifiers independently of user identities.
- Validate inbound or persisted correlation context for format and size.
- Treat correlation as diagnostic context, not proof of authorization or ownership.
- Document parent-child relationships, retries, concurrent work, and ordering.
- Avoid high-cardinality identifiers in metric labels.
- If correlation survives process boundaries, define propagation or persistence,
  access controls, expiry, and cleanup.
- Bound persistent correlation stores and define behavior for corrupt records.
- Explain when correlation is unavailable or deliberately omitted.

Do not assume events from separate processes share a session identifier.
Missing correlation should not be interpreted as evidence that an operation
did not occur.

## Configuration fingerprints

A fingerprint can identify an approved configuration projection without recording
the entire configuration. It is not proof of enforcement and is not a substitute
for a privacy review.

If fingerprints are useful:

- Specify the allow-listed fields and why each is needed.
- Exclude secrets and user content before computing the digest.
- Compute it from effective configuration after relevant defaults and mutations.
- Define canonicalization, including key ordering and whether array order matters.
- Version the projection independently from the API or configuration schema.
- Document which builds and projection versions can be compared.
- Test that newly added fields require an explicit classification decision.

An unkeyed deterministic digest can reveal low-entropy inputs through guessing.
If a keyed construction is justified, define key storage, access, rotation, and
the resulting correlation scope. Do not claim hashing makes sensitive data safe.

## Payload limits and delivery

Set limits for event size, field length, queues, disk usage, rate, and retry
budgets. Define sampling, aggregation, truncation, and dropped-record behavior.

If a projected artifact needs multiple records:

- Keep each record independently parseable.
- Split at complete record or object boundaries, never inside a UTF-8 character.
- Include an approved document identifier, version, chunk index, and chunk count.
- Describe completeness or integrity checks where required.
- Bound document size and reconstruction memory.
- Account for missing, duplicated, delayed, and reordered chunks.

State delivery guarantees per sink. Best-effort diagnostics may tolerate loss;
mandatory audit records may require a different failure policy. Make that decision
explicit rather than letting an unavailable sink silently change application
behavior.

Expose sink failures, retry exhaustion, or dropped records through a safe
operational channel without recursively logging the same failure. Optional
telemetry should not corrupt results, mask the primary error, or block indefinitely.

## Completion, cancellation, and crashes

Instrument authoritative operation boundaries. If multiple paths can observe
completion, prevent duplicate terminal records within the process where practical.
Do not claim exactly-once delivery solely because emission is deduplicated.

Keep crash observation separate from the final operation outcome when a runtime
can recover a failure. A crash sentinel is not necessarily the process's actual
exit status.

Cancellation, shutdown, and crash handlers have restricted time and execution
budgets. Avoid unbounded network calls, unsafe allocation, or locks in contexts
where the runtime forbids them. Document failures that occur before initialization
or cannot be emitted reliably. Telemetry absence is not evidence of success.

Flush and close providers on normal shutdown according to the sink contract.
Specify how outstanding work and buffered records behave on abrupt exit.

## Platform and deployment coverage

Document actual emission and collection support for each relevant platform,
component, build, and deployment mode. Shared event types do not prove all
implementations emit them.

Use explicit statuses such as implemented, unavailable, planned, or not applicable,
with reasons. If an API is a documented no-op on a target, do not claim that
target meets collection requirements.

When correlating application records with operating-system or infrastructure
events, explain which source owns each fact and which join keys are reliable.
Do not invent external providers, fields, or guarantees.

## Build and release configuration

Keep sensitive credentials, routing values, and private identifiers out of source,
tests, documentation, and commits. Use approved secret management where needed.
Validate privileged collection configuration and keep destination metadata,
classification, and routing consistent.

Use isolated destinations and dummy configuration for tests. Public builds and
forks must not gain privileged collection access from copied metadata.
Build-time settings do not replace runtime collection authorization.

Document runtime and package disclosures according to the project's approved
legal and release process. Do not overwrite source license files as an incidental
telemetry step or assume a different license text establishes consent.

## Compatibility and validation

Follow the project's schema evolution policy. Preserve supported event meanings
and field types, and use a new version or name for incompatible changes.
Define how consumers handle unknown additive fields or newer event versions.

Verify:

- Actual emission through affected public operations, including early failures.
- Outcome, state, error, and cleanup semantics.
- Enabled and disabled collection and required authorization boundaries.
- Redaction and allow-list rules with representative sensitive inputs.
- Serialization, Unicode boundaries, payload limits, and chunk reconstruction.
- Correlation across retries, processes, and resource lifetimes where supported.
- Fingerprint canonicalization and projection changes.
- Queue limits, sink failure, drop reporting, shutdown, and crash limitations.
- Platform, build, and deployment coverage against the documented matrix.
- No interference with public output, results, or required error handling.
- Performance overhead against measurable project-specific thresholds.

Use existing test and validation tools. Name automated jobs and required
environments, and report actual results and gaps. Record privacy review,
retention, access, regional processing, deletion, and release decisions with
their responsible owners rather than claiming approval without evidence.

See the [diagnostics guide](../guides/diagnostics.md) for investigation steps and
the [resource lifecycle guidance](container-lifecycle.md) for ownership and recovery.
