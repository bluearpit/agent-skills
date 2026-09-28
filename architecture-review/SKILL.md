---
name: architecture-review
description: >-
  Structural architecture review for codebases and distributed systems:
  module depth, seams, coupling, data ownership, consistency, failure domains,
  APIs, and operability. Use when the user runs /architecture-review, asks for
  an architecture or system design review, reviews service boundaries,
  scaling/reliability trade-offs, or how components should be split. Always
  includes a software-design-principles pass (DRY/SoT/SoC). Complements
  performance-tuning (single-binary speed); do not use that instead of this for
  structural design.
---

# Architecture Review

Review **structure**: how responsibilities, data, and failure are bounded —
in-process modules **and** multi-service / distributed designs.

Related skills (do not collapse into this one):

- `software-design-principles` — **required sub-pass** on every architecture review (DRY / SoT / SoC)
- `performance-tuning` — single-binary CPU/alloc/latency; only if the user also asks for perf

Technique checklists: [reference.md](reference.md).

## Modes

Infer from the request (default: **review**):

| Mode | When | Goal |
|------|------|------|
| **review** | `/architecture-review`, “arch review”, design critique | Findings only; no code/design changes unless asked |
| **design** | “how should we structure X”, greenfield / redesign | Propose 1–2 options with trade-offs; pick a recommendation |
| **advise** | mid-implementation boundary questions | Short guidance; escalate to full review if scope is large |

If the user doesn’t specify a target, default to the **whole repository** (active workspace / git root). Narrow only when they name paths, a service, a PR/diff, or a design doc.

If the user doesn’t specify lenses, cover **both** in-repo structure and distributed concerns that the code/docs imply. Skip distributed sections only when the target is clearly a library or single process with no external dependencies.

## Workflow

```
Arch progress:
- [ ] 1. Scope & lenses
- [ ] 2. Map the system
- [ ] 3. Software-design-principles pass (required)
- [ ] 4. Review (codebase + distributed as applicable)
- [ ] 5. Rank findings
- [ ] 6. Report
```

### 1. Scope & lenses

Identify:

- Target: **default = whole repository** (workspace / git root). Narrow only if the user names paths, a service, a PR/diff, or a design doc
- Stage: greenfield, growth, or brownfield
- Goals: maintainability, reliability, latency, cost, team boundaries, AI/navigability
- Constraints: existing APIs, data stores, compliance, team size

For a whole-repo review: map top-level packages/services first, then sample hot paths and shared modules deeply enough to justify findings — do not claim exhaustive line-by-line coverage. Call out areas not inspected.

Choose lenses (use what applies):

1. **Module / codebase** — depth, seams, coupling, ownership of product facts
2. **Distributed** — services, data, consistency, failure, traffic, ops
3. **Change safety** — how hard is it to evolve without breaking callers

### 2. Map the system

Before judging, sketch (briefly, in the report if useful):

- Trust / process boundaries (client, API, workers, DBs, third parties)
- Data stores and who owns each write path
- Sync vs async edges (RPC, queues, cron, webhooks)
- Critical user journeys and their failure modes

Prefer evidence from code, configs, deploy manifests, and docs over guessing. Label assumptions.

### 3. Software-design-principles pass (required)

Always run this before or interleaved with the structural review — do not skip even if the user only asked for “architecture.”

1. **Read** `~/.agents/skills/software-design-principles/SKILL.md` and follow it for the same scope.
2. Search for duplicated product/policy facts: plan names, prices, CTAs, limits/quotas, entitlement checks, shared labels, magic config literals across bot/web/API/emails/admin.
3. Check single source of truth and separation of concerns (product vs payments vs entitlements vs presentation vs secrets/tunables).
4. Collect findings with Area `design` for the final table.

If nothing in scope looks like packaging/config/constants, still do a quick scan and note “no SoT/DRY issues found” in the report.

### 4. Review

Work top-down. Read [reference.md](reference.md) for the full checklists.

**Codebase (always when code is in scope)**

- Deep vs shallow modules; god files; fan-out hubs
- Layer leaks (presentation ↔ domain ↔ payments ↔ config ↔ infra)
- Missing seams / adapters; hard-to-test cores
- Duplicated policy (detail from the software-design-principles pass)
- API shape: bulk vs chatty; stability promises that freeze bad internals

**Distributed (when multiple processes, stores, or teams)**

- Service / bounded-context cut: is the split about data+change rate, or arbitrary?
- Single-writer ownership; no ambiguous dual writes
- Consistency explicit (strong / eventual / read-your-writes) per flow
- Failure domains: timeouts, retries, idempotency, poison messages, partial outage
- Backpressure, load shedding, queue growth
- Latency budget and fan-out amplification
- Operability: dashboards, traces, alerts, runbooks, deploy/rollback independence

### 5. Rank findings

Severity = blast radius × likelihood × cost-to-change later.

1. **Wrong boundary / dual ownership / consistency ambiguity** on money, identity, or core writes
2. **Failure handling gaps** that cause data loss, duplicate side effects, or cascading outage
3. **SoT / DRY / SoC violations** that let product or entitlement policy drift across surfaces
4. **Shallow / tangled modules** that block safe change
5. **Chatty or over-coupled APIs** across process boundaries
6. **Ops blind spots** (no SLOs, no idempotency keys, no DLQ)

Prefer structural fixes over renaming or style nits.

### 6. Report

Lead with a one-line verdict (e.g. “Clear API/worker split; payment webhooks lack idempotency and dual-write risk on entitlements”).

Then a table, **highest severity first**:

| Severity | Area | Location | Finding |
|----------|------|----------|---------|
| high / medium / low | design \| codebase \| data \| sync \| failure \| api \| ops | `path`, service, or flow name | issue + concrete direction |

Include software-design-principles findings in the same table (Area `design`); do not omit them or bury them only as a side note.

Optionally:

- **Recommended shape** (one paragraph or small mermaid)
- **Do next** (ordered 3 items max)
- **Out of scope / assumed**

**Review mode:** do not implement. **Design mode:** recommend one option; mention the runner-up only if trade-offs are close.

## Principles (always)

1. **Macro over micro** — structure that compounds; not formatting.
2. **Deep modules** — small interface, large implementation; delete/replace test for depth.
3. **One owner per fact** — especially product packaging, entitlements, and authoritative writes.
4. **Make failure explicit** — every remote call has timeout, retry policy, and idempotency story.
5. **Optimize for change** — boundaries should match rate of change and team ownership.
6. **Don’t distribute by default** — a modular monolith beats premature services; split when load, failure isolation, or team boundaries demand it.

## Anti-patterns to flag

- Shared DB tables across “services” with no owner
- Distributed monolith: many deploys, one failure domain
- Chatty sync call chains (A→B→C→D) on the request path
- Dual writes without a transaction, outbox, or single source of truth
- Retries without idempotency on payments, emails, provisioning
- Catch-all god services (“platform”, “common”, “utils” as a dump)
- Consistency “we’ll sync later” with no conflict rule
- Hardcoding product/plan policy in multiple surfaces (caught in the software-design-principles pass; Area `design`)

## Additional resources

- Checklists: [reference.md](reference.md)
- Required companion: `~/.agents/skills/software-design-principles/SKILL.md`
