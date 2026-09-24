# Copilot instructions for `btwld/ack`

## Start here first
- Read `/llms.txt` before making code changes. It is the canonical API reference and should be updated in the same PR when public API changes.
- This is a Melos-managed Dart/Flutter monorepo. Primary packages live under `/packages/*`.

## Repository layout
- `packages/ack`: core runtime validation library.
- `packages/ack_annotations`: annotations for schema-first `@AckInfer()`,
  class-first `@AckModel()`, and frozen legacy `@AckType()` generation.
- `packages/ack_generator`: build_runner generator + unit/integration tests.
- `packages/ack_firebase_ai`: Firebase AI schema adapter.
- `packages/ack_json_schema_builder`: JSON Schema adapter.
- `packages/ack_mcp_dart`: MCP tool input schemas and typed argument validation.
- `example`: sample usage.

## Environment and setup
- Required SDKs: Dart `>=3.9.0 <4.0.0`, Flutter `>=3.35.0` (see `/pubspec.yaml`).
- CI pins Flutter to the version in `/.fvmrc`. Add a new version to `/.github/flutter-releases.json` with its checksum before a workflow may install it.
- Use from repo root:
  1. `dart pub get`
  2. `dart run melos bootstrap`
- Optional one-shot setup script: `./setup.sh` (validates the Flutter SDK, bootstraps the workspace, and installs Node tools when npm is available).

## Commands you should run
- Full CI-equivalent local check: `dart run melos run test --no-select`
  - Runs strict analyze (`dart analyze . --fatal-infos`) and package tests.
- Useful targeted commands:
  - `dart run melos run analyze`
  - `dart run melos run test:dart`
  - `dart run melos run test:flutter`
  - `dart run melos run build` (when generator-related code changes)
  - `dart run melos run test:gen` (for generator changes)
  - `dart run melos run validate-jsonschema` (for JSON Schema conformance tooling)

## Change-scope guidance
- Keep changes minimal and package-scoped; do not refactor unrelated files.
- Prefer existing patterns in each package (schema fluent APIs, existing test structure under `test/`).
- Do not hand-edit generated `*.g.dart` files unless the repo pattern for that area explicitly requires it; prefer rerunning build/golden tooling.

## CI and release notes
- CI is defined in `/.github/workflows/ci.yml`. It runs in this repository, installs the pinned Flutter SDK through `/.github/actions/setup-flutter`, and pins every external action to a commit SHA.
- `/.github/workflows/preflight.yml` holds the release checks: minimum-SDK lanes, JSON Schema Draft-7 batch validation, API comparison against the published baseline, deterministic regeneration, and publish dry runs.
- `/.github/workflows/release.yml` verifies the tag with `dart scripts/verify_release_tag.dart` and reruns the preflight before it publishes.
- Conventional Commits are expected for commit messages.
- Versioning and tag-only publishing are documented in `/PUBLISHING.md`.
  Use `dart run melos version` to prepare versions; publication runs only from
  a reviewed `v*` tag through the release workflow.

## Errors encountered during onboarding and workarounds
1. **Error:** `melos: command not found` when running checks in a fresh environment.  
   **Workaround:** resolve root dependencies with `dart pub get`, then invoke the workspace-local executable via `dart run melos ...`.
2. **Error:** `dart: command not found` in bare sandbox environments.  
   **Workaround:** install Flutter (which includes Dart), then run `./setup.sh`.
3. **Observed CI state:** workflow run may show `conclusion: action_required` with no jobs for PR contexts awaiting approval/permissions.  
   **Workaround:** have a maintainer approve/enable the run, then re-run CI.
