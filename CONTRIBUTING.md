# Contributor's Guide

Below is our guidance for how to report issues, propose new features, and submit contributions via Pull Requests (PRs).

Ideas, questions, bug reports, and code contributions are all welcome. You do not need a finished design to join the discussion. Sharing your use case helps us understand what matters to you and find a useful path forward together.

**Maintaining the project?** See [MAINTAINERS.md](MAINTAINERS.md) for feature discussion, review, and follow-through responsibilities.

## Open Development Workflow

The repo team carries out development in the open. When the team finds issues we file them in this repository. When we propose new ideas or think up new features, we file new feature requests. When we work on fixes or features, we create branches and work on those improvements. And when PRs are reviewed, we review them in public.

The point of doing all this work in public is to ensure that we are holding ourselves to a high degree of transparency, and so that the community sees that we apply the same processes and hold ourselves to the same quality bar as we do to community-submitted issues and PRs.

### Issue Triage

The team triages new issues monthly through a shared developer and PM rotation. During triage, the team uses labels to categorize, manage, and drive the project workflow. Issues are categorized into one of four types — **Bug**, **Feature**,
**Documentation**, or **Task** — and all new issues receive the `Needs-Triage` label until an area label is applied and a response records the next step.
Remove `Needs-Triage` then, including when the response asks for more information; use `Needs-Author-Feedback` while awaiting the author's reply.
Assignment is separate: work is assigned when its scope is clear and someone is ready to take it.

Maintainers record feature decisions and requests for more information in the GitHub issue.

Please keep an eye on GitHub notifications so we can work through questions together. If you need more time, let us know. When a discussion becomes inactive, maintainers may close it with an explanation; you are welcome to return with more information.

### Maintainer issue investigation

Repository administrators, maintainers, and writers can comment `/investigate` on an issue to request an evidence-backed classification. The workflow posts one public comment identifying the issue as a bug, documentation gap, or design decision, with a recommended next step.

When the report lacks enough information to reach a classification, it explicitly mentions the issue author and requests reproduction steps, expected and actual behavior, OS/build, and sanitized logs. It does not create a PR for that outcome.

For a small, unambiguous documentation or test-only change, it may also create one draft PR. It never merges, releases, assigns owners, changes labels, or updates an existing PR. It does not create PRs for production code, schemas, generated SDK files, containment behavior, CI, dependencies, versioning, or security-sensitive work.

Do not use `/investigate` for a security report. Follow [SECURITY.md](./SECURITY.md) instead.

---

## Start a conversation

An issue is a place to ask questions, share a problem, or explore an idea with the team. Before investing in an implementation, find or open an issue so we can connect related work, discuss the approach, and help you focus your effort.

### Search existing issues first

Before filing a new issue, search existing open and closed issues. It is likely that someone else has found the problem you're seeing, and someone may be working on or have already contributed a fix.

If no existing item describes your issue or feature, please file a new one.

### File a new issue

We provide four issue templates under [`.github/ISSUE_TEMPLATE/`](./.github/ISSUE_TEMPLATE/). Pick the one that matches your situation:

| Category | When to use | Template |
|----------|-------------|----------|
| 🐛 Bug Report | Something is broken or behaving unexpectedly | `Bug_Report.yml` |
| 🚀 Feature Request / Idea | A proposal for new functionality or an improvement | `Feature_Request.yml` |
| 📚 Documentation Issue | Docs are incorrect, incomplete, or confusing | `Documentation_Issue.yml` |
| 📋 Task | An actionable work item that doesn't fit the above | `Task.yml` |

**Complete the information requested in the template**. The more information you provide, the more likely your issue will be understood and addressed. Helpful information includes:

* The platform you're on (Windows / Linux / macOS) and architecture (x64 / ARM64).
* Which containment backend is involved.
* **Detailed reproduction steps** — what exact JSON config, command, or SDK call triggers the issue.
* Prefer pasted text (command output, error messages, JSON snippets) over screenshots.
* **If you intend to implement the fix or feature yourself, say so in the issue!** Otherwise we may pick it up or label it `Help-Wanted`.

### Show support for an issue

If you're affected by an issue, use the original issue's 👍 reaction to help us understand its impact. Comments with additional use cases or reproduction details are welcome; reactions work well when you have no new information to add.

---

## Development

### Fork, Clone, Branch, and Create your PR

Start with the approach discussed in your issue.

1. Fork the repository if you haven't already.
2. Clone your fork locally.
3. Create a feature branch.
4. Open a Draft Pull Request early.
5. Work on your changes and push them to the branch.
6. Build and validate locally (see below) before marking the PR ready for review.

### Preserve PR review history

Once a PR is open, including a draft, its commit history helps reviewers track
what changed between reviews. This applies to feature design specs, API
proposals, and implementation PRs.

- Push focused follow-up commits for review feedback.
- Rebasing, squashing, amending published commits, and force-pushing are highly
  discouraged unless a maintainer explicitly requests them.
- If conflicts with `main` arise, merge `main` into the PR branch and resolve
  them in the merge commit instead of rebasing.

Clean up commit history before opening the PR, not during review.

### Merge

Once your PR has been reviewed and approved, a maintainer will merge it into `main`. Your PR will be automatically closed when the merge completes.

---

## Thank you

Thank you in advance for your contribution!