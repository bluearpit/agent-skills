---
name: pr-review
description: Review pull requests for correctness, architecture, design quality, system behavior, maintainability, operational risk, and test coverage. Use when the user asks to review a PR, assess whether changes are safe to merge, evaluate architectural/design impact, or inspect code changes across any repository.
---

# PR Review

Use this skill for pull request reviews across any codebase. Prioritize bugs, regressions, incorrect behavior, architectural drift, and missing verification over style commentary.

## Review Stance

Lead with findings. Order issues by severity. For each finding, explain:

- What can go wrong.
- Where it appears in the diff.
- Why it matters to users, data, operations, or future maintainers.
- What a practical fix or decision point would be.

If there are no blockers, say so clearly and list the meaningful checks not performed.

## Core Review Checklist

### Behavior and Correctness

- Does the code preserve existing behavior unless the PR explicitly intends to change it?
- Are edge cases handled honestly: missing inputs, nulls, empty lists, stale caches, duplicate data, retries, partial failure, low-confidence output, or no external asset?
- Does the final output shape still match downstream consumers?
- Are derived values deterministic and explainable, or are they asserting guesses as facts?
- Are errors surfaced where they should be loud, and degraded where silence is safer?

### Architecture and Design

Run this section using the companion skills. Read each one's `SKILL.md` before reviewing, and resolve its paths against its own directory:

- `architecture-review` (`~/.agents/skills/architecture-review/SKILL.md`): use it in **review** mode, scoped to the PR diff and the code it touches, not the whole repo. Apply its lenses (module depth, seams, coupling, data ownership, consistency, failure domains, APIs, operability) to what the change adds or alters. Include the distributed lenses only when the PR touches service boundaries, queues, storage, or external systems.
- `software-design-principles` (`~/.agents/skills/software-design-principles/SKILL.md`): always run a DRY / single-source-of-truth / separation-of-concerns pass on the diff. Look especially for duplicated constants, config defaults, mappings, or copy, including values duplicated across repos or services.

Fold what these passes find into the single severity-ordered Findings list. Don't produce a separate architecture report unless the user asks for one. Keep the PR-scoped checks below as well:

- Check whether the repo or affected subdirectories contain `CLAUDE.md`, `AGENTS.md`, or similar agent guidance files, and apply any project-specific conventions they define.
- Does the change fit the existing module boundaries and ownership model?
- Is runtime code taking on work that belongs in offline build steps, data pipelines, configuration, or shared services?
- Are abstractions added only where they reduce real complexity or match an existing pattern?
- Does the design make future extension easier without hiding important control flow?
- Does the PR introduce coupling between unrelated systems, tools, or configs?

### Source of Truth and Reference Data

- Hardcoded aliases, option IDs, geography lists, status rankings, lookup constants, and business mappings should have a clear owner.
- Prefer existing canonical sources, shared utilities, config, database tables, or offline-generated artifacts over hand-maintained runtime maps.
- If a small runtime map is acceptable, check that it is scoped, sourced, documented, tested, and has a path to move if it grows.
- Watch for duplicated source-of-truth logic that can drift across services.

### Data, Provenance, and Auditability

- Check whether `source_ref`, confidence, method/provenance fields, timestamps, IDs, and audit records remain truthful after transforms, merges, or collapse steps.
- Verify that cached/exported records can be interpreted later without rerunning the workflow.
- Ensure a field being absent, null, below threshold, or not searched are distinguishable when that matters.
- For list/append/union behavior, check whether item-level provenance is needed rather than one lossy field-level summary.

### Tooling, Config, and Workflow Coupling

- Profile/config filters should preserve required policy, rules, tool order, overrides, seeds, and helper fields.
- A config knob should drive only the tool or workflow it is meant to drive.
- Tools should not be marked complete before their prerequisites exist unless they can retry safely.
- New CLIs/scripts should compile, import, parse arguments, and fail safely on missing credentials or assets.

### External Dependencies and Operations

- Check S3/database/search/geocoding/LLM/API dependencies for existence assumptions, credential assumptions, caching, fallback, and retry behavior.
- For batch jobs, evals, exports, and migrations, check checkpoint/resume, idempotency, overwrite behavior, concurrency, and one-record failure isolation.
- Avoid destructive or expensive operations in review unless the user explicitly asks.
- Verify deployment or one-time build steps are documented when runtime behavior depends on generated assets.

### Testing and Verification

Prefer targeted verification over broad, expensive runs:

- Unit tests for new pure logic.
- Regression tests for bugs found in review.
- Import/compile checks for new scripts.
- Small local smoke tests for runtime behavior.
- Before/after output comparison for retrieval, ranking, prompt, matching, or scoring changes.
- Trace/log inspection when the behavior depends on multi-step tool flow.

Call out when a PR description claims tests or behavior that are not actually present in the diff.

## Suggested Workflow

1. Identify base/head and whether the PR is stacked.
2. Check repo/subdirectory guidance files such as `CLAUDE.md`, `AGENTS.md`, or equivalent.
3. Read PR description, commits, changed files, and diff.
4. Inspect changed code in context, not only the patch.
5. Run the `architecture-review` (PR-scoped, review mode) and `software-design-principles` passes on the diff.
6. Run focused checks if practical and safe.
7. Report findings first, then open questions, then verification.

Useful commands:

```bash
gh pr view <number> --json number,title,body,baseRefName,headRefName,files,commits,reviewDecision
gh pr diff <number>
git diff --stat <base>...<head>
```

## Output Template

```markdown
## Findings

1. <Severity/context> <issue>
   `<path>`
   Why it matters and suggested fix.

## Open Questions

- <question or assumption>

## Verification

- <tests/checks run>
- <checks not run>

## Merge Readiness

<Blocked / okay after comments / looks good from this pass>
```
