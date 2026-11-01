---
title: Diagnosing development and runtime failures
description: Repository-neutral troubleshooting steps for reproducing failures and verifying fixes.
---

> Audience: Contributors, maintainers, and operators

Investigate failures using the repository's existing tooling and operational
procedures. Adapt these steps to the affected application, service, library,
tool, infrastructure, or documentation workflow.

## Capture the failure

- Record the operation, exact error, expected result, and actual result.
- Identify the revision, component, dependency versions, configuration, and
  environment. Include platform details only when relevant.
- Save the command or request and the smallest useful logs, stack trace, test
  output, or correlation identifiers.
- Note frequency, user impact, recent changes, and whether retries differ.
- Remove credentials, tokens, personal data, and confidential payloads before
  sharing evidence. Use the private disclosure process for suspected vulnerabilities.

## Reproduce safely

- Use a local, test, or isolated environment where possible.
- Start with the smallest input or scenario that reproduces the failure.
- Document prerequisites and exact steps so another contributor can repeat them.
- Change one relevant variable at a time, such as version, configuration, or input.
- If reproduction requires production access, follow the project's approval and
  incident procedures. Do not alter shared resources or run destructive checks
  without authorization.

## Trace the failing path

- Follow the operation from its public entry point through validation, owning
  logic, dependencies, state changes, and cleanup.
- Compare the failing scenario with a known working case.
- Check existing documentation, related issues, recent changes, and test scenarios.
- Use the project's debugger, structured logs, traces, metrics, or build reports
  to identify the first actionable failure rather than later cascading errors.
- Distinguish invalid input, unsupported capabilities, permission failures,
  dependency failures, and implementation defects using evidence.
- If more diagnostics are needed, collect only relevant information and follow
  the project's logging and data-retention rules.

## Recover and verify

- Determine what state or resources remain after failure before retrying.
- Follow documented cleanup or rollback procedures. Check that retries will not
  duplicate work, corrupt data, or hide the original failure.
- Fix the responsible component rather than suppressing errors or bypassing
  validation. Keep unrelated changes separate.
- Add a regression scenario for a code fix where practical, showing that it
  detects the original failure and passes with the fix.
- Run targeted checks and relevant integration scenarios. Verify both the corrected
  behavior and existing behavior that must remain unchanged.
- For operational recovery without a code change, verify restored service behavior,
  state consistency, and relevant health indicators.

## Share actionable findings

Record the root cause, affected scope, reproduction steps, sanitized evidence,
fix or recovery steps, and verification results in the agreed tracking item or
review. Separate confirmed facts from hypotheses and state what was not verified.

Escalate unresolved failures to the responsible owners with the smallest useful
reproduction and evidence. Update canonical troubleshooting instructions when a
new failure mode or remedy will help future users.
