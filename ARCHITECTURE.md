# Architecture decisions

This log explains choices that would be costly to reverse or easy to misread.
The [README](README.md) introduces current concepts; linked guides own API details.
These entries are backfilled from implementation and PR history. Dates identify
implementation events, not a new approval of the design. When changing a choice,
retain its rationale and link the superseded entry to its replacement.

## Stored models and field presence

Status: current; immutable model work landed in
[PR #133](https://github.com/btwld/ack/pull/133), 2026-09-01.

Generated models store typed values instead of implementing their boundary Map
or scalar interface; public constructors are unchecked, while parsing and JSON
encoding validate. Presence, null, and unknown-key capture remain separate so
PATCH and round-trip data are not lost; hand-written constructors remain
responsible for their own defensive copies.

See [model generation](docs/core-concepts/typesafe-schemas.mdx) and
[presence/null configuration](docs/core-concepts/configuration.mdx).

## Unified annotations

Status: current; package and `@Schemable` consolidation landed in
[PR #190](https://github.com/btwld/ack/pull/190), 2026-10-01;
the `@Validate` namespace is part of 2.0.

`package:ack/ack.dart` owns `@Schemable`, `@AckKey`, and the `@Validate` namespace
so schema-first and class-first generation share the API without a separately
versioned annotations package. Namespacing avoids the former top-level format
and constraint-name collisions, at the cost of a source migration for 1.x users.

See [exact substitutions](docs/getting-started/migration-guide.mdx).

## Single-part generation

Status: current; introduced 2026-10-09 in
[the 2.0 consolidation](https://github.com/btwld/ack/commit/b3caec7).
Supersedes the [two-part build contract](#superseded-two-part-model-design).

Ack emits model and JSON helpers through the shared `.g.dart` pipeline, removing
its delegated `json_serializable` pass and Ack-specific second public part.
This simplifies consumer setup and generator coexistence, while making Ack
responsible for JSON emission correctness and regression coverage.

See [the builder](packages/ack_generator/lib/src/builder.dart) and
[the generation guide](docs/core-concepts/typesafe-schemas.mdx).

## Stable Dart for 2.0

Status: current; [PR #227](https://github.com/btwld/ack/pull/227), 2026-10-21,
reverted the merged augmentation design in
[PR #225](https://github.com/btwld/ack/pull/225) on `release/2.0`.

Release 2.0 targets stable Dart and retains generated mixins/facades because the
augmentation implementation required a beta SDK and experiment flags.
The extra source declarations remain until an approved stable-toolchain migration;
the experiment continues separately on `release/2.0-augmentations`.

Supported minimums live in package `pubspec.yaml` files; installation guidance is
[here](docs/getting-started/installation.mdx).

## Codec boundary and failure semantics

Status: current; boundary export fixes include
[PR #155](https://github.com/btwld/ack/pull/155), with decoder Error propagation
in [the 2.0 cleanup](https://github.com/btwld/ack/commit/b66b26f), 2026-10-10.

Codecs parse boundary data into runtime values and validate/encode those values
back; export projects runtime constraints only when their wire meaning survives.
Callback `Error` values propagate as programming failures, while other thrown
objects become schema failures, so `safeParse` is not a blanket exception barrier.

See [codecs](docs/core-concepts/codecs.mdx) and
[error handling](docs/core-concepts/error-handling.mdx).

## Detached validating wire views

Status: current; breaking update in
[PR #246](https://github.com/btwld/ack/pull/246), 2026-10-27.

`Ack.preserveBoundary` runs the full inner object parse, discards decoded values,
and returns a detached, recursively unmodifiable copy of the original JSON map
without invoking an encoder. Inner defaults do not materialize into that copy;
null/default policy belongs on the wrapper, and nested wire views can repeat
subtree copying.

See [the wire-view contract](packages/ack/lib/src/schemas/boundary_schema.dart).

## Preserve imported JSON Schema semantics

Status: current; introduced in the 2026-10-09
[2.0 redesign](https://github.com/btwld/ack/commit/b3caec7), refined by
[PR #231](https://github.com/btwld/ack/pull/231) and
[PR #239](https://github.com/btwld/ack/pull/239).

Imported schemas preserve supported Draft 2020-12 resource semantics on export,
with format assertion opt-in unless their dialect requires it; native Ack schemas
retain their Draft-7 representation. Consumers needing legacy export must request
Draft-7 lowering and handle unsupported conversion, trading convenience for an
explicit failure instead of silently changing validation.

See [JSON Schema integration](docs/guides/json-schema-integration.mdx).

## Adapter ownership

Status: current; integration contracts corrected in
[PR #236](https://github.com/btwld/ack/pull/236), 2026-10-27.

Non-JSON adapters consume `AckSchemaModel`, while JSON-map adapters use the
renderer, keeping wrapper/resource semantics in Ack and unsupported target
features explicit. Firebase passes JSON Schema through; MCP validates typed
inputs and leaves output validation/serialization to callbacks, so provider or
transport acceptance does not replace Ack validation.

See [using adapters](docs/guides/ecosystem-integrations.mdx) and
[writing adapters](docs/guides/creating-schema-converter-packages.mdx).

## Coordinated and guarded releases

Status: current; release gating in
[PR #134](https://github.com/btwld/ack/pull/134), simplified to one approval in
[PR #181](https://github.com/btwld/ack/pull/181).

Publishable packages share one version and a reviewed `v<version>` tag, with
ancestry/version verification and preflight ahead of the workflow approval gate.
This avoids unguarded local releases and dependency skew; a new package's first
upload needs the documented bootstrap exception before automated publishing works.

[PUBLISHING.md](PUBLISHING.md) owns the runbook. Generator memory constraints and
the stopped-run rule belong in [CONTRIBUTING.md](CONTRIBUTING.md) and
[AGENTS.md](AGENTS.md), following [PR #179](https://github.com/btwld/ack/pull/179).

## Superseded: two-part model design

Status: superseded for 2.0 by [single-part generation](#single-part-generation),
[unified annotations](#unified-annotations), and
[validating wire views](#detached-validating-wire-views).

The historical model-generation design described `.ack.dart` plus `.ack.g.dart`,
delegated JSON emission, and legacy annotation names; it was deleted in
[commit 3391f85](https://github.com/btwld/ack/commit/3391f85), 2026-09-27.
Keep [its last pre-deletion text](https://github.com/btwld/ack/blob/c3c21116fd554f33d61043e0063c3d7340b25990/docs/architecture/ackinfer-model-generation.md)
as historical context rather than restoring an obsolete API specification.
