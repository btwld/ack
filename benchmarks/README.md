# ACK package benchmarks

Reproducible comparisons and a [roadmap](PLAN.md) for ACK performance work.
This is development tooling, not a dependency of any published ACK package.
The existing `packages/ack/benchmark/parse_benchmark.dart` remains a quick
ACK-only microbenchmark; it is not the cross-package comparison harness.

## Comparison matrix

| Engine | Pinned version | Public operation | Category |
|---|---|---|---|
| ACK fluent | Workspace source | `safeParse` | Parser + structured errors |
| ACK JSON Schema import | Workspace source | `safeParse` | Parser + structured errors |
| Validart | 3.0.2 | `safeParse` | Parser + structured errors |
| Dart json_schema | 5.2.2 | `validate` | Validation + structured errors |
| Zod | 4.6.5 | `safeParse` | Parser + structured errors |
| Valibot | 1.5.0 | `safeParse` | Parser + structured errors |
| Ajv | 8.20.0 | Compiled validator, `allErrors: true` | Validation + errors |
| Acanthis | 2.0.0 | `tryParse` | Excluded: correctness probe cannot finish |

All new Dart measurements run in **JIT** processes; JavaScript runs in Node/V8.
Default: seven runtime/engine lanes and 23 timed workloads, or **161 result
cells**, each measured in three independent processes. Leo discontinued AOT
measurements on 2026-10-08; earlier AOT artifacts are retained as history, but
the driver no longer accepts that runtime.

These are not interchangeable products. ACK creates validated output maps
and lists, with immutable object output; Ajv/json_schema validate the input.
Native error structures and per-constraint collection behavior differ.
Cross-runtime numbers describe end-to-end configurations, not language speed.
Keep parser/validator categories visible when interpreting results.

**Optimization scope confirmed by Leo:** improve the existing `safeParse`
API only, preserving parsed output, ownership, diagnostics, callbacks, and
normalization. Validation-only API exploration is out of scope. Ajv remains
a differently scoped comparison, not a reason to remove parsing work.

See the [safeParse implementation follow-up](../reports/ACK%20safeParse%20optimization%20results.md)
for isolated candidate measurements, decisions, and the fresh cumulative
comparison. Rejected candidates and adverse results are preserved alongside
the retained changes.

### Acanthis exclusion

The initial check against Acanthis 2.0.0 did not finish after several minutes.
Source inspection found this path:

1. `AcanthisString.tryParseInternal` handles a wrong-type value.
2. `AcanthisType.valueOnFailure` calls `mock(0)` for a recovery string.
3. `AcanthisString.mock` generates mixed-case alphanumeric chunks and appends
   them until they match the pattern. An uppercase character already in the
   buffer cannot be repaired by appending more characters to match an anchored
   lowercase-only pattern.

Minimal expression:

```dart
ac.string()
    .min(3)
    .max(64)
    .pattern(RegExp(r'^[a-z][a-z0-9_-]*$'))
    .tryParse(0);
```

No Acanthis performance number is reported. Its adapter and exact dependency
are retained for a future upstream fix. Do not add a manual type guard, weaken
its schema, or silently omit failing cases to admit it to the same ranking.
An explicit future recheck can use `--engines acanthis --check
--worker-timeout 10`; that fails on timeout without retrying.

## Setup

Prerequisites: Dart **3.13+**, Node **22+**, Python **3.9+**, macOS or Linux.
Acanthis 2 requires Dart 3.13, so this private package is intentionally outside
the Melos workspace. ACK itself retains its Dart 3.9 minimum.
Both dependency lockfiles are checked in. Initial setup, from the repo root:

```sh
(cd benchmarks/dart && dart pub get --enforce-lockfile)
(cd benchmarks/node && npm ci --ignore-scripts)
```

No root bootstrap, Flutter build, or generator suite is needed for this tool.

## Run

```sh
# Harness integrity, type checking, and complete cross-engine conformance.
python3 -m unittest discover -s benchmarks -p 'test_*.py' -v
(cd benchmarks/dart && dart analyze --fatal-infos)
node --check benchmarks/node/worker.mjs
python3 benchmarks/run.py --check

# Short smoke run; do not use its timings as a baseline.
python3 benchmarks/run.py --quick

# Full current desktop matrix: 3 forks x 7 samples x 161 cells.
python3 benchmarks/run.py

# Longer, controlled repeat before release/publication.
python3 benchmarks/run.py --forks 10 --samples 15 \
  --warmup-ms 500 --sample-ms 200 --worker-timeout 600

# Focused native-Dart comparison.
python3 benchmarks/run.py --runtimes dart-jit --engines ack,validart

# Separate payload-scaling cohort; no AOT or schema-construction phase.
python3 benchmarks/run.py --suite scaling --sizes 1,10,100,1000,10000 \
  --engines ack,ack-json-schema,ajv --forks 4 --samples 9 \
  --warmup-ms 500 --sample-ms 100 --worker-timeout 600
```

Use `--output <new-directory>` for a chosen artifact location. Existing
directories are never overwritten. `--seed` fixes lane and case ordering.
Results default to ignored `benchmarks/results/<UTC timestamp>/`.
The driver takes a machine-wide advisory lock and launches one worker at a
time. It does not stop unrelated applications or generator tests.

### Compare ACK revisions in the same run

```sh
# Pair the current ACK source with the revision before PR #213.
python3 benchmarks/run.py \
  --baseline-ref b740f6b1d8254982543dcd87a22bcf64df0e2bed --forks 4
```

`--baseline-ref` stages only the old ACK source in the output directory and
uses the same current benchmark workers, corpus, and enforced dependency lock.
It does not check out a branch, change your working tree, or run generator tests.
Both revisions are correctness-checked before timing. Each old/new
ACK lane runs in adjacent processes with the same case order; process order
alternates AB/BA across forks. Use an even fork count for balanced order.
Competitors are rerun alongside these pairs.

For sequential uncommitted optimization experiments, use
`--baseline-source <snapshot-root>` instead of `--baseline-ref`. The snapshot
must contain `packages/ack/lib/` and `packages/ack/pubspec.yaml`. The driver
copies it into the run directory, uses identical current workers/locks, and
checks source hashes before and after timing. Each candidate must be compared
with its immediate predecessor; do not attribute cumulative gains to one edit.
Use `--cases <comma-separated-workload-names>` for a focused confirmation.
This filters timings only: every selected engine still checks the entire
suite's correctness corpus. Preserve the initial complete run and include
regression candidates in any focused follow-up, not just favorable rows.

The default full comparison adds two baseline ACK lanes: nine lanes and 207
result cells. `comparison.md` shows all 46 paired ACK comparisons. Its speedup
is the median of per-fork baseline/current ratios (>1 means current was faster),
not a ratio against a historical run. Pair ranges are observed variation, not
confidence intervals. Pairing mitigates time drift but does not remove machine
load, differing process histories, or sampling noise.

Timeouts, failures, and interrupts retain a non-complete `results.json` and
do not retry. Do not restart any externally stopped test run without asking
Leo first. Benchmark timing should run without other builds/tests or heavy
workloads; the advisory lock only coordinates this benchmark driver.

### Payload scaling

`--suite scaling` creates a separate version-2 corpus; it does not change the
common corpus or make historical results interchangeable. A fixed nested
schema covers every requested size, with its `maxItems` set to the largest
requested size. Every size has valid, first-invalid, last-invalid, all-invalid,
and valid decode+validate cases. Construction is deliberately outside this
cohort. The default sizes are 1, 10, 100, 1,000, and 10,000 items.

Each case has four independent, varying payloads to bound fixture memory.
Sizes up to 100,000 are accepted explicitly, but larger corpora can consume
substantial memory before timing; inspect memory pressure before escalating.
Untimed boundary probes include the maximum accepted and first rejected item
counts. `caseMetadata` records item counts and compact UTF-8 payload sizes;
these serialized sizes are **not** the in-memory object graph size.

Invalid cases are traversal diagnostics, not equivalent all-errors rankings:
ACK imported-schema validation may stop within a failing keyword while Ajv
uses `allErrors: true`. Decode+validate includes both JSON decoding and the
API call; it is not a decode-only baseline. Keep these distinctions visible
when attributing the scaling gap.

## Corpus and equivalence

`corpus.py` is the single deterministic source. The driver writes one JSON
file that both runtimes read. There are 16 varying payloads per timed case,
not one constant object. Data is decoded before timing except in the explicit
`decode+validate` cases. One operation means **one entire payload**, including
all 1/50/500 nested items where applicable.

| Family | Timed cases |
|---|---|
| Constrained string | Valid, wrong type, failing pattern |
| Strict flat object | Valid, first/last/many errors, missing, null, unknown key, numeric string, 50% invalid mix |
| Nested object list | Valid with 1/50/500 items; 50 items with first/last/all items invalid |
| JSON decoding | Flat and 50-item nested valid payloads |
| Construction + first validation | String, flat, and 50-item nested valid payloads |

Additional untimed probes cover length/range boundaries, fractional numbers,
collection limits, wrong roots, and nested missing/unknown/null values.
Each common-corpus worker makes **800 assertions of expected validity** (400
vectors, twice), also checking successful output equality and non-mutation of
the input. The default five-size scaling corpus makes 222 validity assertions
per worker (111 vectors, twice), with the same output/mutation checks.
Every selected runtime/engine must pass before any timings are accepted.
Timed batches verify a success/failure checksum and retain the last native
result. The result is consumed outside timing to prevent dead-code removal.

The schemas use only strings with ASCII fixtures and a shared anchored regex,
bounded integers, booleans, arrays, and required strict objects. No coercion,
defaults, transforms, optional fields, formats, remote references, or async
validation is enabled. Integral JSON values use integer literals, not `1.0`.
This is a common-input subset, **not** full JSON Schema conformance testing.

Canonical schemas declare Draft-7. ACK's importer only accepts 2020-12, so its
adapter substitutes the dialect URI. Every other schema keyword used here has
the same meaning in those drafts. Draft-specific features must get their own
cohort rather than extending this comparison silently.

### Timing boundaries

- `validate`: schemas and inputs already exist; native result/error creation
  is included; exception throwing and error-to-string formatting are not.
- `decode+validate`: includes JSON string decoding and the above operation;
  it excludes JSON encoding, I/O, HTTP, and network transfer.
- `construct+validate`: includes the shared-subset-to-native-schema adapter,
  native schema construction, closure setup, and first validation. Ajv gets a
  fresh engine each time to prevent schema cache hits; its instance setup and
  compilation are included. This is **warm repeated construction**, not cold
  startup, and generic adapter overhead is part of this metric.

## Measurement and artifacts

### JIT CPU and heap-state diagnostics

Run profiles separately from throughput measurements and project tests:

```sh
python3 benchmarks/profile_jit.py \
  --corpus <scaling-run>/corpus.json --engine ack \
  --case nested-1000-valid --mode validate \
  --warmup-ms 3000 --operations 2000 --output <new-profile-directory>
```

The controller uses the authenticated loopback Dart VM service, checks the
selected case before warming, clears CPU samples, and captures the exact
`Timeline.now` operation window. It keeps raw CPU samples and before/after
heap-state snapshots. `ack-json-schema`, `decode-only`, `decode+validate`, and
JSON-round-trip `clone` modes support diagnostic controls; cloning is neither
validation nor equivalent to ACK's immutable parsed output. Instrumented
timings are not competitor-ranking results.
Keep operation windows short enough for the effective profiler buffer and
inspect sample timestamps, stack truncation, and sample count in `profile.json`.

The controller saves the original VM response in `cpu-samples.json` and
timestamp-filtered frames in `cpu-samples-window.json`. Observed VM replies
included some samples outside the requested interval; the cause is not yet
established. Reports select `start <= timestamp < end` explicitly. Serialized
stacks omit stub/invisible frames, so **leaf-most reported function-frame
counts are not VM/native self ticks**. Stack-presence counts overlap across
callers. VM/native-entry tags are a separate, overlapping view. Original
aggregate self ticks are shown separately with their unfiltered population;
the exported stacks cannot reconstruct exact windowed self time.

**Dart 3.13.4 caveat:** its VM implementation populates allocation-profile
`accumulatedSize` / `instancesAccumulated` from the same heap census as current
fields. They are not reliable cumulative allocation counters. This tool does
not calculate allocation bytes/op, force GC, or mislabel heap deltas as
allocation rates. Use separate allocation-trace diagnostics when needed.
See [the JIT performance audit](../reports/ACK%20JIT%20performance%20audit.md)
for pinned SDK source evidence and the optimization investigation plan.

### Throughput methodology

- Run Dart JIT and Node separately. No new AOT measurements are collected,
  and no Flutter device claims are inferred from these desktop runs.
- Use independent processes, seeded shuffled lane and case order, a monotonic
  high-resolution timer, adaptive full-corpus batches, and per-case warmup.
- Default warmup target: 100 ms; sample target: 50 ms. Batch sizes grow by
  powers of two when elapsed time is below half the target. Targets are not
  precise wall-clock guarantees; actual elapsed times and iterations are saved.
  Slow compilation cases can exceed the target even with one corpus cycle.
- No manual GC, per-operation timer calls, outlier deletion, or subtracting a
  guessed loop overhead. Closure/index/checksum overhead stays in all results.
- Calculate ns/op for each batch, the median within each process, then the
  median of those process medians. Also keep process medians and their range.
  These are **batch averages**, not request-latency p95/p99 measurements.
- Record CPU/OS/architecture, load averages, SDK versions, dependency versions
  and copied locks, corpus/source/binary hashes, git revision and dirty state,
  commands, random order, all samples, and checksums.

`report.md` contains tables in microseconds per payload; `results.json` retains
raw timings and metadata. Cells whose fork-median range exceeds 20% of the
median are flagged as noisy. That threshold is descriptive, not a significance
test. Three forks and load averages alone do not establish a controlled lab
result. Do not gate releases or advertise a universal winner from this run.

See [PLAN.md](PLAN.md) for Flutter devices, web, allocation/startup/code-size
measurements, code generation/codecs, optional JVM comparisons, and CI rollout.

## Sources

Package versions and public APIs were inspected on 2026-10-08:

- [ACK](https://github.com/btwld/ack)
- [Acanthis](https://pub.dev/packages/acanthis/versions/2.0.0)
- [Validart](https://pub.dev/packages/validart/versions/3.0.2)
- [json_schema](https://pub.dev/packages/json_schema/versions/5.2.2)
- [Zod](https://www.npmjs.com/package/zod/v/4.6.5)
- [Valibot](https://www.npmjs.com/package/valibot/v/1.5.0)
- [Ajv options](https://ajv.js.org/options.html)

Vine is a candidate for an additional Dart lane, but its normalization and
coercion policy need an explicit equivalence audit first. Formz represents
form state, and json_serializable maps models; neither is a drop-in schema
validator. They belong in separate application/workflow comparisons.
