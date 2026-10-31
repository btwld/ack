# Architecture decisions

This log records choices and tradeoffs; the [README](README.md) introduces the
current core concepts. Dates identify implementation or adoption events recovered
from history, not a new design approval. Specs, API contracts, and runbooks remain
in the linked documents. Preserve superseded entries and link their replacements.

## Stored models

Date: 2026-09-01. Status: current. History: [#133](https://github.com/btwld/ack/pull/133).

Generated models store typed values instead of implementing their boundary Map or
scalar interface, so schema validation and application representation have clear
owners. Constructors are unchecked and hand-written constructors own their
copying, so callers must use parsing for untrusted input and JSON encoding for
validated output.

Contract: [model generation](docs/core-concepts/typesafe-schemas.mdx).

## Field presence and unknown keys

Date: 2026-10-10. Status: current. History: [PATCH presence](https://github.com/btwld/ack/commit/556e426).

Keep omission, null, and unknown-key capture separate, using `JsonMaybe` when a
class must preserve PATCH intent. This avoids losing wire information, but
schema authors must choose presence, nullability, and capture policies explicitly.

Contract: [configuration](docs/core-concepts/configuration.mdx) and
[class projection](docs/core-concepts/typesafe-schemas.mdx#additional-properties).

## Unified annotations

Date: 2026-10-14. Status: current. History: [#190](https://github.com/btwld/ack/pull/190), [Validate namespace](https://github.com/btwld/ack/commit/5b11c5a), and [AckKey consolidation](https://github.com/btwld/ack/commit/b4c4f05).

`package:ack/ack.dart` owns `@Schemable`, `@AckKey`, and the `@Validate` namespace
so generation shares an API without a separately versioned annotations package.
Namespacing avoids the former top-level format and constraint-name collisions,
at the cost of a source migration for 1.x users.

Migration: [exact substitutions](docs/getting-started/migration-guide.mdx).

## Single-part generation

Date: 2026-10-09. Status: current. History: [2.0 consolidation](https://github.com/btwld/ack/commit/b3caec7).

Ack emits model and JSON helpers through the shared `.g.dart` pipeline, removing
its delegated `json_serializable` pass and Ack-specific second public part.
This simplifies consumer setup and generator coexistence, while making Ack
responsible for JSON emission correctness and regression coverage.

Replaces: [two-part model design](#two-part-model-design-superseded).
Contract: [generation guide](docs/core-concepts/typesafe-schemas.mdx).

## Stable Dart for 2.0

Date: 2026-10-21. Status: current. History: [#227](https://github.com/btwld/ack/pull/227), reverting [#225](https://github.com/btwld/ack/pull/225).

Release 2.0 targets stable Dart and retains generated mixins/facades because the
merged augmentation implementation required a beta SDK and experiment flags.
The extra source declarations remain until an approved stable-toolchain migration;
the experiment continues separately on `release/2.0-augmentations`.

Requirements: [installation](docs/getting-started/installation.mdx).

## Codec boundaries and failures

Date: 2026-10-10. Status: current. History: [2.0 cleanup](https://github.com/btwld/ack/commit/b66b26f), following [#155](https://github.com/btwld/ack/pull/155).

Codecs decode boundary data into runtime values and validate/encode it back;
export projects runtime constraints only when their wire meaning survives.
Callback `Error` values propagate as programming failures while other thrown
objects become schema failures, so `safeParse` is not a blanket exception barrier.

Contracts: [codecs](docs/core-concepts/codecs.mdx) and
[error handling](docs/core-concepts/error-handling.mdx).

## Detached validating wire views

Date: 2026-10-27. Status: current. History: [#246](https://github.com/btwld/ack/pull/246).

`Ack.preserveBoundary` runs the full inner object parse but returns an immutable
copy of the original JSON without invoking an encoder, preserving wire values
instead of replacing them with decoded values. Inner defaults do not materialize
into that copy, wrapper null/default policy remains explicit, and nested wire
views can repeat subtree copying.

Contract: [wire views](packages/ack/lib/src/schemas/boundary_schema.dart).

## Preserve imported JSON Schema semantics

Date: 2026-10-09. Status: current. History: [2.0 redesign](https://github.com/btwld/ack/commit/b3caec7), refined by [#231](https://github.com/btwld/ack/pull/231) and [#239](https://github.com/btwld/ack/pull/239).

Imported schemas preserve supported Draft 2020-12 resource semantics, with
format assertion opt-in unless their dialect requires it; native Ack schemas
retain Draft-7 output. Explicit legacy lowering can fail, trading convenience
for preserved meaning instead of silently changing validation.

Contract: [JSON Schema integration](docs/guides/json-schema-integration.mdx).

## Adapter ownership

Date: 2026-10-27. Status: current. History: [#236](https://github.com/btwld/ack/pull/236).

Non-JSON adapters consume `AckSchemaModel` and JSON-map adapters use the renderer,
keeping wrapper/resource handling in Ack while making unsupported target features
explicit. Firebase passes JSON Schema through and MCP owns input validation;
callers still own output validation and any provider/transport limitations.

Guides: [using adapters](docs/guides/ecosystem-integrations.mdx) and
[writing adapters](docs/guides/creating-schema-converter-packages.mdx).

## Coordinated and guarded releases

Date: 2026-09-29. Status: current. History: [#181](https://github.com/btwld/ack/pull/181), following release gating in [#134](https://github.com/btwld/ack/pull/134).

Publishable packages share a version and reviewed `v<version>` tag, with
verification and preflight ahead of the workflow approval gate, avoiding
unguarded releases and dependency skew. Releases require coordinated preparation,
and new packages need the documented first-upload bootstrap before automation.

Runbook: [PUBLISHING.md](PUBLISHING.md).

## Generator resource limits

Date: 2026-09-29. Status: current. History: [#179](https://github.com/btwld/ack/pull/179).

Serialize generator suites per machine and ask before restarting an externally
stopped run because simultaneous checkouts exhausted memory and swap.
The cost is slower parallel iteration; tagged integration builds and the unit-only
command provide a smaller check while retaining full validation for generator work.

Runbook and safety rules: [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md).

## Two-part model design (superseded)

Date: 2026-09-27. Status: superseded for 2.0. History: [deletion 3391f85](https://github.com/btwld/ack/commit/3391f85).

The historical design used two generated parts and delegated JSON emission,
which preserved the legacy path but coupled consumers to an extra build phase.
The [last pre-deletion text](https://github.com/btwld/ack/blob/c3c21116fd554f33d61043e0063c3d7340b25990/docs/architecture/ackinfer-model-generation.md)
remains historical evidence; restoring it would teach obsolete APIs.

Replacements: [single-part generation](#single-part-generation),
[unified annotations](#unified-annotations), and
[validating wire views](#detached-validating-wire-views).
