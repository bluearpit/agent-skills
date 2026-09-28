---
name: performance-tuning
description: >-
  Review and improve single-binary / library performance using measurement-first
  tuning, cost estimation, and techniques from Abseil Performance Hints (Dean &
  Ghemawat). Use when the user runs /performance-tuning, asks to optimize or
  speed up code, review a hot path, reduce allocations/latency/CPU, fix a flat
  profile, or apply performance best practices. Not for distributed-systems or
  ML-hardware architecture design.
---

# Performance Tuning

Apply this skill for **single-binary / library performance** work. Prefer
measurement and estimation over speculative micro-optimizations. Do **not**
expand into distributed system design or ML accelerator tuning unless the user
explicitly asks.

Primary reference: [Abseil Performance Hints](https://abseil.io/fast/hints.html)
(Jeff Dean, Sanjay Ghemawat). Detailed technique checklist:
[reference.md](reference.md).

## Modes

Infer from the user request (default: **review**):

| Mode | When | Goal |
|------|------|------|
| **review** | `/performance-tuning`, "perf review", examine a diff/file/hot path | Findings only; do not change code unless asked |
| **optimize** | "make this faster", "reduce allocations", fix a measured hotspot | Propose or implement changes, with evidence |
| **advise** | writing new code / choosing APIs or data structures | Prefer the faster option when complexity cost is low |

## Workflow

Copy and track:

```
Perf progress:
- [ ] 1. Scope & context
- [ ] 2. Estimate or measure
- [ ] 3. Rank opportunities
- [ ] 4. Recommend / implement
- [ ] 5. Report
```

### 1. Scope & context

Identify:

- **What** is under review (paths, functions, diff, PR, or runtime symptom)
- **Language / runtime** (C++, Go, Java, Python, JS, etc.)
- **Role of the code**: test, app-specific, or shared library
- **Hot vs cold**: init/setup vs per-request / per-element path
- **Constraints**: API stability, readability budget, latency vs throughput vs memory

Library and hot-path code deserve low-complexity wins even without a profile.
Test code: prioritize asymptotic cost and keep tests fast.

### 2. Estimate or measure

**Prefer evidence in this order:**

1. Existing profiles / benchmarks the user provides
2. Repo microbenchmarks or profilers already in use (`pprof`, `perf`, language bench libs)
3. Back-of-the-envelope costs (see cost table in [reference.md](reference.md))
4. Static review only — label findings as **unmeasured**

When profiles are **flat**: many small wins still matter; look higher in the
call stack; reduce allocations; replace overly general code; gather HW-counter
or allocation profiles.

Do not claim percentage wins without a benchmark or a clear estimation model.

### 3. Rank opportunities

Prioritize by expected impact × confidence, typically:

1. **Algorithmic / structural** (complexity class, batching, avoid repeated work)
2. **Allocation & memory layout** (fewer allocs, denser data, better locality)
3. **API / interface** (bulk ops, views, pre-sized buffers) — prefer changes inside encapsulation boundaries
4. **Synchronization** (amortize locks, shorten critical sections, reduce contention)
5. **Micro / codegen** (inlining, templates, SIMD) — only after larger wins or on proven hotspots

Read [reference.md](reference.md) when you need the technique catalog for a
language or finding category.

### 4. Recommend or implement

**Review mode:** findings only; no code changes unless the user asks.

**Optimize / advise mode:**

- Prefer the faster alternative when it does **not** meaningfully hurt clarity
- Keep public APIs stable when possible; optimize behind deep modules
- Avoid optimizing one-shot or clearly cold code
- Prefer project-native containers/APIs (e.g. Abseil types in C++ Abseil codebases)
- Pair non-trivial changes with a microbenchmark or measurement plan when feasible

### 5. Report

Lead with a one-line verdict (e.g. "3 high-impact opportunities on the parse path; no measured profile provided").

Then a compact table, **highest severity first**:

| Severity | Location | Finding | Evidence |
|----------|----------|---------|----------|
| high / medium / low | `file:line` or symbol | short issue + fix direction | profile / estimate / unmeasured |

**Severity guide:**

- **high** — wrong complexity class, huge alloc churn on hot path, severe lock contention, unnecessary I/O/RPC in a loop
- **medium** — clear alloc/copy/layout/API win on a likely hot path; bulk API missing
- **low** — micro-optimization, cold path, speculative without evidence

Optionally add:

- **Quick wins** (low complexity)
- **Do not bother** (cold / one-shot / clarity-destroying)
- **Measure next** (what to profile or benchmark)

## Core principles (always apply)

1. Knuth’s critical ~3%: small efficiencies matter when the cost is low and the code is hot or widely reused.
2. Ignoring performance everywhere yields a **flat profile** with no lever to pull.
3. Estimate before building heavy alternatives; measure before claiming wins.
4. Many 1% improvements compound — especially with stable microbenchmarks.
5. Overly general code (regex vs prefix, protobuf vs struct, nested maps) is a common tax.
6. Out of scope unless asked: multi-service architecture, capacity planning, ML hardware.

## Anti-patterns to flag

- Premature complexity for unmeasured cold paths
- Per-item API calls / locks / allocations in tight loops (missing bulk/batch)
- Pointer-chasing or node-based containers where a flat/dense structure fits
- Repeated work inside loops that could be hoisted, cached, or precomputed
- Logging / stats / excess Status objects on hot paths
- Holding locks while doing I/O or heavy computation
- Optimizing with no before/after measurement plan when the change is risky

## Additional resources

- Technique catalog & cost table: [reference.md](reference.md)
- Source article: https://abseil.io/fast/hints.html
