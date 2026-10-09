---
kind: plan
date: 2026-10-08
repository: btwld/ack
branch: leoafarias/dart-flutter-packages-benchmark
commit: b740f6b1d8254982543dcd87a22bcf64df0e2bed
worktree: /Users/leofarias/conductor/workspaces/ack/edinburgh-v1
skill: engineering-kit:writing-plans
session: null
status: draft
---

# ACK benchmark program

## Goal and scope

Give maintainers reproducible evidence for performance decisions, with fair
comparisons against Dart alternatives and JavaScript reference libraries.
Use this workspace for the tooling and keep benchmark dependencies outside
published packages. The original benchmark work makes no runtime ACK changes.
Leo subsequently requested importing PR #213 and repeating the comparison;
that follow-up is recorded below. No branch rename, new PR, or publication is
part of this work.

Leo confirmed Dart plus JavaScript as the comparison scope on 2026-10-08.
Java/JVM is only an optional future cohort, not part of the requested run.
Flutter-specific results require real application and physical-device
measurements, not an inference from desktop Dart.

On 2026-10-08 Leo discontinued new AOT measurements. All active benchmark
work now targets Dart JIT and Node, including payload scaling and the
allocation/JSON/validation audit. Earlier AOT artifacts remain historical;
the proposed Flutter release/device throughput phase below is deferred under
this direction and must not be started automatically.

Leo also confirmed **existing `safeParse` only** for the optimization audit.
Do not explore or introduce a validation-only API or boolean-only ACK lane.
Preserve output construction/ownership, diagnostics, defaults, transforms,
normalization, and callback behavior. Any specialization experiment must
preserve the existing full-parse contract; Ajv remains a contextual comparator.

## Repository findings

- At the original `b740f6b1` baseline, `packages/ack/benchmark/parse_benchmark.dart`
  had seven ACK-only operations, fixed iterations, one measured batch, and no
  consumed result or machine metadata. PR #213 improves that harness and adds
  `large_schema_benchmark.dart`; neither is the cross-package comparison.
- `packages/ack/test/performance/basic_performance_test.dart` contains broad
  test-time performance checks; unit-test timing is not the release benchmark.
- `tools/package.json` already uses Ajv and Zod for schema tooling; benchmark
  packages use separate exact-version locks to avoid perturbing those tools.
- ACK's importer is 2020-12-only; Dart json_schema is Draft-7. Use their shared
  keyword subset, with dialect substitution documented, for direct comparison.
- `CONTRIBUTING.md` requires serialized generator testing. Never run the
  ack_generator suite in multiple worktrees, and never restart an externally
  stopped run without asking Leo first.

## Acceptance criteria

1. All advertised comparison cells have matching input/constraint contracts,
   verified valid/invalid outcomes, and explicit operation categories.
2. Every number links to raw samples, exact source/dependency/corpus identity,
   runtime mode, machine metadata, and a reproducible command.
3. Distinguish measured, noisy, excluded, and not-yet-measured work.
4. Keep setup, decoding, validation, error rendering, and serialization costs
   separate. Never describe batch-average quantiles as request tail latency.
5. Flutter debug results, emulator results, and physical release builds must
   not be mixed into a desktop parser leaderboard.
6. No release gates until stable, same-machine baseline variance is established.

## Phase 1 — Common desktop corpus and first baseline

**Files:** `benchmarks/corpus.py`, `benchmarks/dart/`, `benchmarks/node/`,
`benchmarks/run.py`, `benchmarks/test_harness.py`, `benchmarks/README.md`.

**Implemented (original matrix; JIT/Node only going forward):**

- Seven admitted implementations in 11 runtime lanes (Dart JIT/AOT and Node).
- 23 timed workloads: primitive, flat, nested scaling, invalid/mixed input,
  decoding, and construction. 400 correctness vectors, checked twice/lane.
- Exact locks, typed Dart adapters, strict analyzer settings, integrity tests,
  sequential process execution, machine-wide driver lock, bounded workers,
  deterministic randomization, warmup/calibration, consumed native results,
  raw samples and report generation.
- Acanthis 2.0.0 excluded for a nonterminating wrong-type recovery path, with
  source-based diagnosis and reproduction in the README. Do not retry the
  interrupted probe automatically. No fabricated or selectively filtered row.

**Validation:** run the commands in the README. Baseline timing must follow
checks, not overlap them. Review process-median spread before interpreting it.
The first local run is exploratory: this machine also runs development apps.

## Phase 2 — Semantic and workload expansion

**Dependencies:** Phase 1 correctness gates and stable artifact contract.

**Components:** extend the shared corpus and adapter contracts, not one engine
in isolation. Keep separate cohorts when behavior is not equivalent.

**Work:**

- Optional versus missing versus nullable, strip/reject/preserve unknown keys,
  shared Unicode/format policy, recursive schemas, refs, discriminated unions,
  adversarial regex/size limits, wider/deeper objects, and larger mixed batches.
- Explicit all-errors versus fail-fast cohorts, plus separately timed error
  path extraction and human-readable rendering. Validate diagnostic paths, not
  just failure booleans, before comparing error collection costs.
- ACK codecs: datetime, URI, enum, custom decode/encode, transforms, and
  bidirectional round trips. Include only equivalent APIs from competitors;
  list unsupported features instead of emulating them without accounting.
- Hand-written validation as a clearly labeled feature-limited floor.
  Vine/other Dart validators only after auditing coercion and error semantics.

**Validation:** positive and negative boundary vectors for every new rule;
output equality and mutation checks; unsupported contracts must fail or get an
explicit cohort exclusion. No memory-pressure or unbounded fuzzing in normal CI.

## Phase 3 — Generation and model workflows

**Dependencies:** explicit schema/model equivalence from Phase 2.

**Components:** isolated fixture packages using `ack_generator`, build_runner,
and comparable model-mapping tooling such as json_serializable.

**Work:** measure clean build time, no-op rebuild, one-model incremental rebuild,
generated source size, generated model parse/encode and `toJson` costs. Separate
validation from mapping-only baselines. Save SDK, dependency cache state,
build_runner output and artifact sizes. Never include network download time in
generator throughput; report dependency setup separately if it matters.

**Validation:** generated output must compile and round-trip shared fixtures.
Follow `CONTRIBUTING.md` generator-unit/full-suite requirements for generator
changes. A machine-wide generator/build lock is needed before this phase runs
in automation; the desktop benchmark lock does not coordinate existing suites.

## Phase 4 — Flutter application/device measurements

**Deferred:** the later no-AOT direction supersedes the release-throughput
proposal below. It is retained as design history, not a current run request.

**Dependencies:** reusable Dart corpus/adapters and physical-device access.

**Components:** a private Flutter benchmark app and integration/profile driver,
added outside the published packages. No app UI work is required for Phase 1.

**Work:**

- Physical Android ARM64 and physical iPhone, each in release mode for
  throughput; profile mode separately for DevTools allocation/CPU diagnostics.
- Reused schema per screen/service, created outside `build`; no rebuild or
  `setState` inside measured parsing loops. Report device, OS, Flutter/Dart
  versions, build flags, power/thermal state, and baseline app configuration.
- Small field validation during typing; nested API payload parsing on the UI
  isolate; identical work offloaded to an isolate, with transfer/startup costs
  measured separately. Do not use an isolate for tiny validation by default.
- Frame build/raster timings and missed-frame counts at the device's refresh
  rate. Relate synchronous work to 16.67 ms (60 Hz) / 8.33 ms (120 Hz) budgets
  without treating those theoretical budgets as measured frame latency.
- Profile allocation bytes/op and retained heap with supported tooling, and
  separately measure release startup and app-size delta against the same
  no-validator app. Process RSS is not Dart heap allocation or package size.
- Formz comparison only as a form-state workflow with equivalent validators;
  no claim that its state abstraction replaces schema parsing.

**Validation:** repeat on idle devices with stable thermal/power conditions;
verify shared corpus and app outputs before profiling; save raw frame/timeline
artifacts. Emulators may smoke-test correctness, not establish device baselines.

## Phase 5 — Web and optional JVM context

**Dependencies:** correct cross-runtime corpus and explicit product question.

**Web:** Dart JS and Wasm builds, browser versions, and release Flutter web
where relevant. Compare with Zod/Valibot/Ajv in that same browser/device. Record
compressed bundle-size deltas, load/compile/startup, warm validation, and error
costs independently. Node numbers are not a browser proxy.

**JVM (optional):** use a pinned Java 21+ environment and JMH with multiple
forks, warmup, and a consumed result. Evaluate networknt JSON Schema Validator
for the same dialect/keyword cohort. Jackson is a decoding/mapping baseline;
Jakarta/Hibernate Validator requires a separate bean-validation cohort. Record
GC/JVM flags and JSON node representation. No global Dart-versus-Java score.

**Validation:** reuse the canonical JSON vectors, publish cross-runtime results
as configurations, and disclose differences in output copying/error semantics.
Do not add JVM build dependencies until that comparison is actually needed.

## Phase 6 — Controlled baselines, reporting, and regression policy

**Dependencies:** sufficient independent repeat runs for each target platform.

**Components:** initially a manual benchmark workflow with downloadable
artifacts, then scheduled dedicated-runner measurements; PR correctness checks
may use shared CI. Add workflow files only when runners and retention are chosen.

**Work:**

- Pin SDK/runtime images and hardware; keep cold/warm states and phases apart.
- Compare ACK changes against its own same-environment baseline. Competitor
  upgrades are separate baseline revisions with their lockfile/correctness diff.
- Start with >=10 process forks and >=15 samples per case, then use observed
  variance to choose sample counts. Estimate intervals at the process level,
  not by pretending every loop iteration is an independent experiment.
- Set practical per-workload thresholds after measuring variance, require a
  repeatable effect beyond that variance, and never gate on shared-runner noise.
- Publish methodology, feature/category matrix, exact artifacts and exclusions;
  no cherry-picked headline or aggregate across unlike operations. A chart
  needs units, runtime/build mode, and uncertainty or observed spread.
- Keep baseline history and allow inspection of regressions before optimizing
  ACK. Any implementation optimization needs separate correctness regression
  tests and the relevant package checks from `CONTRIBUTING.md`.

**Validation:** compare identical source across repeated runs before enabling
regression alerts. Confirm interrupted/incomplete artifacts cannot become a
baseline and upstream exclusions are visible in every report.

## Readiness

The desktop harness is executable now. Phases 2–6 are scoped follow-up work,
not measured claims. Physical-device access, runner ownership, target product
workloads, and demand for Java determine their scheduling. No SDK/runtime or
public ACK API change is required to adopt the current tooling.

## 2026-10-08 initial execution evidence (before PR #213)

- Completed the full implemented desktop matrix: 253 cells, 33 measurement
  workers, 5,313 samples, three process repetitions. Every preflight and
  measurement worker passed its 800 validity checks and output/mutation checks.
- Nine harness integrity tests, strict Dart analysis, formatting, and Node
  syntax checks passed. No generator suite was started; no core ACK source was
  changed. All work remains on the original workspace branch.
- Apple M2 Max, macOS 27.0 ARM64, Dart 3.13.4, Node 26.4.0. This development
  machine was heavily loaded: one-minute load 44.4 at start, 39.1 at finish
  on 12 logical CPUs. 219/253 cells exceeded the 20% process-spread flag.
- These are exploratory observations, not an approved regression baseline or
  evidence of a universal package winner. Controlled reruns remain Phase 6.
- Local evidence: `.context/benchmark-baseline-2026-10-08/FINDINGS.md`, with
  full tables, raw JSON, exact corpus/locks, and a measurement-source snapshot.
  Portable archive: `.context/ack-benchmark-2026-10-08.zip`.
- Acanthis's nonterminating probe was stopped by this agent and not retried.
  The confirmed Dart + JavaScript scope does not require a JVM lane.

## 2026-10-08 PR #213 paired rerun

- Fast-forwarded the existing branch to PR #213's
  `82d21b0d27a8ee6ac6c06b9843ffaad9f7b91c51`, preserving the benchmark work.
  Baseline: `b740f6b1d8254982543dcd87a22bcf64df0e2bed`.
- Added `--baseline-ref`: isolated baseline ACK source, identical current
  workers and dependency locks, adjacent baseline/current processes, identical
  case order within each pair, and balanced AB/BA order across four forks.
  Competitors were freshly rerun; historical medians were not used for ratios.
- Completed 345 cells, 92 paired revision comparisons, 60 timing workers,
  and 9,660 samples. All 15 preflight and 60 timing workers passed 800 validity
  checks each, plus successful-output equality and input non-mutation checks.
  Raw-sample statistics, pair order, completeness, and source/lock identities
  were independently verified after completion.
- For 50-item valid payloads, observed paired speedups were 1.40x native AOT,
  1.30x native JIT, 1.58x imported AOT, and 1.60x imported JIT, each faster in
  4/4 pairs. Error-heavy and construction cases were mixed; full findings
  include unfavorable observations as well as improvements.
- The machine was exceptionally busy: one-minute load 232.2 at start and 31.0
  at finish on 12 logical CPUs; 321/345 cells exceeded the 20% spread flag.
  These are exploratory observations, not confirmed effect sizes or a release
  gate. Repeat on an idle, controlled machine before performance claims.
- JSON Schema export and `safeEncode` are not timed by this common corpus;
  they need separate correctness-gated workloads to assess those PR changes.
  Flutter unit tests do not substitute for physical-device measurements.
- Evidence: `.context/benchmark-pr213-comparison/FINDINGS.md`, `comparison.md`,
  `report.md`, `results.json`, and `integrity-check.json`.
- Full project checks then completed serially: 2,170 project tests passed,
  four opt-in live Firebase tests skipped, and two generator cases hit their
  30-second timeout. Both timed-out cases passed in a separate isolated
  diagnostic run (23.1 seconds total); the original failures remain recorded.
  All nine real-build integration files completed, and strict analysis passed
  for all six workspace packages. Full logs and diagnostic links are in
  `.context/pr213-full-checks/REPORT.md`.

## 2026-10-08 JIT optimization audit follow-up

Leo requested no further AOT measurements and an expert audit of Dart JIT,
JSON, memory, and ACK's gap to Ajv before changing the runtime. The driver now
rejects AOT explicitly; original source snapshots and AOT artifacts remain
unchanged as historical evidence.

- Added a separate scaling corpus for 1/10/100/1,000/10,000 nested items,
  with a fixed schema, four varying inputs per case, first/last/all-error
  variants, decoding, upper-bound probes, and compact UTF-8 size metadata.
- Added an isolated JIT CPU/heap-state profiling worker and VM-service
  controller. Profiling and throughput runs must remain separate and follow
  the full test run. Diagnostic JSON cloning is not ACK-equivalent parsing.
- Source research is synthesized in
  [ACK JIT performance audit](../reports/ACK%20JIT%20performance%20audit.md),
  with source-backed distinctions between parsed output ownership, schema
  interpretation, generated validators, JSON/map representation, and GC.
- The installed Dart 3.13.4 VM serializes accumulated allocation-profile
  fields from current-heap census values. Do not infer allocated bytes/op
  from them. Preserve raw CPU samples and label heap snapshots honestly.
- Prioritize measured, behavior-preserving reductions within `safeParse`.
  Validation-only APIs are excluded by Leo's confirmed scope. Preserve
  callbacks, output ownership, JSON safety, and diagnostics; specialization
  is relevant only if it preserves the existing full-parse contract.
- No new ACK runtime optimization was implemented by this audit. New
  scaling/profile results and full-check status are recorded in the report.

### Completed evidence

- Completed all 75 scaling cells (25 workloads × three engines), four
  process forks and nine samples per cell: 2,700 timed samples. All three
  preflight and 12 timing workers passed their 222 validity assertions
  each, plus output/non-mutation checks. Source hashes remained unchanged.
- At 10,000 valid items (~493 KB JSON), observed whole-payload medians were
  10,991.641 µs native ACK JIT, 8,629.193 µs imported ACK JIT, and 1,160.183 µs
  Ajv Node. Increasing payload did not close the gap. These APIs have
  different parsed-output ownership contracts; this is not a language score.
- 54/75 cells exceeded the 20% process-spread flag, with one-minute load
  25.72 → 18.40 on 12 logical CPUs. Treat the run as exploratory, not a gate.
  Raw process distributions and the PNG/SVG chart are preserved under
  `.context/benchmark-jit-scaling-2026-10-08/` with exact source/lock snapshots.
- Completed eight separate JIT diagnostic profiles covering valid native
  and imported parsing, decode-only, decode+parse, JSON-round-trip cloning,
  and invalid payloads. No profile overlapped throughput timing or tests.
  Filtered stacks show imported copying in 336/1,008 valid-input samples
  and 374/385 all-invalid samples; these are overlapping stack-presence
  counts, not allocation counts or exact CPU self-time attribution.
- Corrected derived profile reports after inspecting the pinned SDK:
  serialized stacks omit stub/invisible frames, so leaf-most reported
  frames are not VM/native self ticks. VM replies also included samples
  outside the requested window; the cause remains unconfirmed. Preserve
  the raw replies, filter timestamps explicitly, and keep unfiltered VM
  aggregate ticks separate. Postprocessing verified unchanged raw hashes.
  See `.context/jit-profile-summary.md` and
  `.context/jit-profile-postprocessing.json`.
- All 22 current Python harness integrity tests passed, including AOT
  rejection and exact-window/sample-label safeguards. The full project
  outcome remains 2,170 passes, four skips, and two initial generator
  timeouts; both timed-out cases passed in a separate isolated diagnostic.
  No full-suite rerun was needed for the reporting-only corrections.

### Next implementation sequence

1. Establish repeatable JIT baselines on an idle machine; preserve matched
   schema, corpus, output ownership, diagnostics, and process-level spread.
2. Make one behavior-preserving change at a time: lazy error storage and
   unnecessary result/constraint dispatch are initial measured-path targets.
   Validate actual surviving allocations before redesigning contexts.
3. Add dedicated equality/uniqueness and `Ack.any()` workloads for the
   source-identified algorithmic opportunities absent from this corpus.
4. Only then prototype copy/evaluation fusion or a fully equivalent
   specialized Dart parser behind existing `safeParse` behavior. Do not
   substitute a boolean-only validator or propose a new validation-only API.

## Authorized safeParse optimization execution

Leo requested implementation, correctness verification, and benchmarks after
each step. JIT only; no new APIs, commits, pushes, or other-workspace edits.

- [x] Freeze initial ACK source; run unchanged-source paired noise control.
- [x] Candidate 1: lazy shared constraint-error storage; compatibility tests
  and paired common/scaling benchmarks before deciding whether to retain it.
- [x] Candidate 2: audit direct composite result handling; preserve virtual
  methods on public result subclasses. Test cached immutable object-property
  entries instead, without changing callback or error order, and benchmark
  separately against retained source.
- [x] Candidate 3: native integer-input fast path, including numeric boundary
  and JavaScript correctness checks; verify and benchmark separately.
- [x] Candidate 4: singleton imported-type fast path; retain union behavior,
  diagnostic locations, snapshot semantics; verify and benchmark separately.
- [x] Final integrated checks, paired cumulative JIT/Node comparison, and
  report including rejected/inconclusive candidates and host variability.

Start with four balanced AB/BA process pairs, seven samples, and 300 ms
warmup per case; confirm promising changes with additional independent pairs.
Every candidate gets common small/mixed/invalid and 1–10,000-item scaling
coverage. Reject semantic differences. Retain timing improvements only when
repeated process-pair evidence supports them without repeatable material
regressions; source-level allocation reductions alone are not proof. With
the host still loaded, do not claim universal speedups or release thresholds.
High-risk copy/evaluation fusion remains a later design, not this patch set.

### Execution evidence

- Baseline strict analysis and 1,397 ACK tests passed (five new lifecycle
  compatibility tests). Harness: 24 checks passed, including source-baseline
  detachment. A redundant test import was fixed before the successful run.
- `00-control` compared identical ACK source in four AB/BA pairs over 15
  scaling workloads. Most ratios were near 1, but 100-item first-error showed
  an apparent 1.288x speedup despite identical code. Individual pair ranges
  were wide. Source/preflight gates passed; load declined 16.38 → 13.87.
  Do not infer a small optimization from one run. Evidence is under
  `.context/safeparse-optimization/`; candidate 1 is now under test.

- Candidate 1 retained after full common/scaling runs and a separate
  eight-pair confirmation. All 1,397 tests and strict analysis passed.
  Confirmation paired medians: 500 valid 1.050x (6/8 faster), 10,000 valid
  1.053x (6/8), 10,000 decode+parse 1.093x (6/8). Earlier large valid cases
  were 4/4 faster, but their larger effect sizes did not repeat. Scalar and
  construction regressions did not repeat. These are modest exploratory
  gains, not an allocation-rate measurement or a controlled release claim.
- Direct `.match` replacement would bypass public `Ok`/`Fail` subclass
  overrides. Candidate 2 instead caches entries of ObjectSchema's immutable
  property map, preserves result dispatch, and adds observable subclass and
  schema/error-order checks. Only the parse traversal uses this cache.
- Candidate 2 rejected after full runs and eight-pair confirmation. The cache
  helped 10,000-item valid parsing (1.129x; 8/8 faster) but numeric-string
  rejection regressed twice (confirmation 0.964x; 0/8 faster), and it retains
  extra memory per used schema. Restore only that library change; preserve
  compatibility tests and all negative evidence. Candidate 3 starts from the
  retained candidate 1 snapshot, not the rejected cache.
- Candidate 3 rejected after full runs and eight-pair confirmation. Numeric
  behavior passed on VM and Node (including exact non-finite error type and
  negative zero); all 1,400 ACK tests passed. Initial flat valid/mixed gains
  disappeared (confirmation 1.006x/1.001x, both 4/8 faster), and 10,000 valid
  items were slower in 6/8 confirmation pairs (0.941x). No reproducible
  benefit justifies the extra branch. Keep tests and evidence, restore the
  original integer implementation, and start candidate 4 from retained 1.
- Candidate 4 retained after full common/scaling and independent eight-pair
  confirmation. Strict analysis and 1,403 ACK tests passed; new type-contract
  checks passed on VM and Node. Confirmation: flat valid 1.058x (8/8 faster),
  500 valid 1.083x (8/8), 10,000 valid 1.054x (8/8), and 10,000 decode+parse
  1.072x (8/8). The first-run construction/all-invalid regressions did not
  repeat. This is local JIT evidence, not an allocation or universal claim.
- Final integration passed: 2,183 project tests and four opt-in live Firebase
  skips; all 394 generator tests passed in a serialized run with a documented
  two-minute timeout. ACK checks reused the identical candidate-4 source.
  Node contracts: 21 passed, one expected platform skip. Harness: 26 passed.
- Fresh common matrix (seven current engines, two ACK baselines) and scaling
  matrix (ACK native/imported plus baselines and Ajv) completed with 332 cells,
  9,296 timed batches, and verified raw/source/corpus/lock identities. At
  10,000 valid items: native 8.145 ms, imported 6.022 ms, Ajv 0.975 ms. Paired
  cumulative ratios: 1.044x native and 1.039x imported, both 3/4 faster.
- Followed up adverse native common cells with eight independent pairs;
  mixed inputs 1.023x (7/8 faster), many errors 1.018x (5/8), construction
  0.995x (3/8), wrong type 1.003x (4/8). The earlier material slowdowns did not
  repeat; 500 valid items improved 1.023x (7/8). Both retained changes remain.
  No claim that every workload improved, or that Ajv performs equivalent work.
- [Completed implementation report](../reports/ACK%20safeParse%20optimization%20results.md)
  includes every candidate decision, adverse results, all-result CSV exports,
  scaling figure, fresh package context, and verification provenance. No AOT,
  commits, pushes, branch rename, or other-workspace repository edits.
