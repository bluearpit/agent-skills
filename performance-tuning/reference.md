# Performance Tuning Reference

Condensed from [Abseil Performance Hints](https://abseil.io/fast/hints.html)
(Dean & Ghemawat). Language-agnostic principles first; C++/Abseil notes where
the article is concrete. Adapt names to the local stack.

## Rough operation costs

Orders of magnitude for back-of-the-envelope estimates (approximate):

| Operation | ~Cost |
|-----------|------:|
| L1 cache reference | 0.5 ns |
| L2 cache reference | 3 ns |
| Branch mispredict | 5 ns |
| Mutex lock/unlock (uncontended) | 15 ns |
| Main memory reference | 50 ns |
| Compress 1K with Snappy | 1,000 ns |
| Read 4KB from SSD | 20,000 ns |
| Round trip, same datacenter | 50,000 ns |
| Read 1MB sequentially from memory | 64,000 ns |
| Read 1MB over 100 Gbps network | 100,000 ns |
| Read 1MB from SSD | 1,000,000 ns |
| Disk seek | 5,000,000 ns |
| Read 1MB sequentially from disk | 10,000,000 ns |
| Packet CA→Netherlands→CA | 150,000,000 ns |

Also track **domain costs**: DB point read, cloud API call, HTML render, etc.

**Estimation recipe:** count expensive ops × unit cost; for latency with
concurrency, account for overlap. Discard alternatives that lose by 10×+ before
implementing them.

## Measurement

- Start with a whole-program profiler (`pprof`, `perf`, language equivalents)
- Prefer production-shaped binaries (optimization + useful symbols)
- Microbenchmarks: fast iteration and regression guards; watch for non-representative results
- Lock-contention profiles when CPU looks low but latency is high
- Allocation / heap profiles when CPU is flat
- Hardware counter profiles for cache-miss dominated code

**Flat profiles:** stack many small wins; restructure loops near the top of
flame graphs; algorithmic changes higher up; specialize overly general code;
cut allocations (allocator time + cache-line churn).

## API considerations

- Prefer **deep modules**: optimize inside without breaking callers
- Be careful adding features that constrain implementations (e.g. iterator/pointer stability)
- **Bulk APIs**: amortize boundary crossing, locking, and validation
- **View types** (`string_view` / spans / slices): avoid copies at API boundaries
- **Pre-allocated / pre-computed args**: let callers reuse buffers and scratch space
- Prefer **thread-compatible** types (external sync) over internally locked types when callers can batch under one lock

## Algorithmic improvements

Highest leverage when available:

- Improve complexity class (e.g. N² → N log N / N)
- Build structures in one shot instead of incremental maintenance
- Replace general algorithms with ones that exploit known structure
- Batch work to enable better algorithms (sort once, scan, union-find, etc.)

## Better memory representation

- **Compact** hot or large data; watch false sharing if densely packing contended fields
- **Layout**: reduce padding; smaller numeric/enum types; hot fields together; hot read-only away from hot mutable; cold data at end / indirect / separate array
- **Indices instead of pointers** into contiguous arrays (smaller refs + locality)
- **Batched / flat storage** over node-based maps/trees when possible
- **Inlined storage** for typically-small containers (caveat: large `sizeof(T)`)
- Prefer **single-level maps with compound keys** over nested maps — unless the outer key is huge and heavily duplicated (then nesting can win)
- **Arenas** for many short-lived related objects (don't park short-lived objects in long-lived arenas)
- **Arrays / vectors** instead of maps when keys are dense small ints or enums
- **Bit vectors** instead of sets of small integers when appropriate

## Reduce allocations

Allocations cost allocator time, init/destroy, and cache footprint.

- Avoid allocs on common paths (static/empty singletons, SSO, stack buffers)
- `reserve` / pre-size containers
- Avoid copies; prefer moves and views
- Reuse temporary buffers across loop iterations / requests
- Prefer fewer, larger allocations over many tiny ones

## Avoid unnecessary work

- **Fast paths** for common simple cases; keep rare cases correct but separate
- Precompute expensive facts once
- Hoist invariant work out of loops
- Defer expensive work until needed
- Specialize (templates, monomorphization, per-type paths) on proven hotspots
- Cache repeated pure computations (mind invalidation and memory)
- Help the compiler: clearer ownership, fewer aliases, visible lifetimes
- Cut stats / metrics overhead on hot paths
- Avoid logging on hot paths (or gate cheaply)

## Code size

- Excess code size hurts i-cache and TLB
- Trim aggressive inlining of cold paths
- Inline hot tiny functions carefully; don't inline huge cold callees
- Reduce template / generic instantiation fan-out when it bloats binaries
- Avoid repeated heavy container operations that expand to lots of code in loops

## Parallelization and synchronization

- Parallelize expensive independent work in **batches**, not per tiny item
- Amortize lock acquisition (bulk ops under one lock)
- Keep critical sections short; no I/O under locks
- Shard to reduce contention when a single lock is hot
- Reduce false sharing (pad/align contended atomics/counters)
- Reduce context-switch churn; buffer channels / queues for pipelines
- Consider lock-free only with clear evidence and expertise
- SIMD on proven data-parallel hot loops

## Serialization / protobufs

- Protobuf (and similar) is costly for tight in-process compute loops
- Prefer native structs/arrays for hot inner data; proto at boundaries
- Avoid repeated field reflection / dynamic patterns on hot paths
- Reuse messages; `Clear` + reuse; reserve repeated fields when sizes known
- Don't use proto as a general in-memory object model for hot data

## C++ / Abseil-oriented defaults

When the codebase already uses Abseil (or equivalents):

| Need | Prefer |
|------|--------|
| Hash map/set hot path | `absl::flat_hash_map` / `flat_hash_set` (or local equivalent) |
| Ordered map, better cache behavior than tree nodes | `absl::btree_map` / `btree_set` |
| Small vector | `absl::InlinedVector` |
| Small integer set | bit vector / inlined bit set |
| Status on hot success path | limit `Status` / `StatusOr` churn; prefer cheaper error strategies where safe |

Still validate with benchmarks — container choice depends on size, lookup mix, and key cost.

## Ranking cheat sheet

When stuck, ask in order:

1. Can we do **less work** or a **better algorithm**?
2. Can we **batch** and cross the expensive boundary once?
3. Can we **allocate less** and keep data **denser / hotter together**?
4. Can we **wait / precompute / cache** instead of recomputing?
5. Can we **parallelize** or **reduce sync** without wrecking simplicity?
6. Only then: instruction-level / SIMD / micro-opt.

## Citation

Dean, J., & Ghemawat, S. (2023–2025). *Performance Hints*. https://abseil.io/fast/hints.html
