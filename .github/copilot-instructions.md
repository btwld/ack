# Copilot instructions for `btwld/ack`

## Start here first
- Read `/llms.txt` before making code changes. It is the canonical API reference and should be updated in the same PR when public API changes.
- This is a Melos-managed Dart/Flutter monorepo. Primary packages live under `/packages/*`.

## Repository layout
- `packages/ack`: core runtime validation library.
- `packages/ack_annotations`: source annotations (`@AckModel`, `@AckType`).
- `packages/ack_generator`: build_runner generator + golden tests.
- `packages/ack_firebase_ai`: Firebase AI schema adapter.
- `packages/ack_json_schema_builder`: JSON Schema adapter.
- `example`: sample usage.

## Environment and setup
- Required SDKs: Dart `>=3.8.0 <4.0.0`, Flutter `>=3.16.0` (see `/pubspec.yaml`).
- Use from repo root:
  1. `dart pub global activate melos`
  2. `melos bootstrap`
- Optional one-shot setup script: `./setup.sh` (installs Dart/Melos/Node tools where possible).

## Commands you should run
- Full CI-equivalent local check: `melos run test --no-select`
  - Runs strict analyze (`dart analyze . --fatal-infos`) and package tests.
- Useful targeted commands:
  - `melos run analyze`
  - `melos run test:dart`
  - `melos run test:flutter`
  - `melos run build` (when generator-related code changes)
  - `melos run test:gen` / `melos run update-golden:all` (for generator golden updates)
  - `melos run validate-jsonschema` (for JSON Schema conformance tooling)

## Change-scope guidance
- Keep changes minimal and package-scoped; do not refactor unrelated files.
- Prefer existing patterns in each package (schema fluent APIs, existing test structure under `test/`).
- Do not hand-edit generated `*.g.dart` files unless the repo pattern for that area explicitly requires it; prefer rerunning build/golden tooling.

## CI and release notes
- CI is defined in `/.github/workflows/ci.yml` and delegates to `btwld/dart-actions/.github/workflows/ci.yml@main` with DCM enabled.
- Conventional Commits are expected for commit messages.
- Publishing/versioning flows are documented in `/PUBLISHING.md` (`melos version`, `melos publish`).

## Errors encountered during onboarding and workarounds
1. **Error:** `melos: command not found` when running checks in a fresh environment.  
   **Workaround:** install Melos (`dart pub global activate melos`) and/or invoke via `dart run melos ...` after Dart is available.
2. **Error:** `dart: command not found` in bare sandbox environments.  
   **Workaround:** install Dart SDK first (or run `./setup.sh`), then bootstrap with Melos.
3. **Observed CI state:** workflow run may show `conclusion: action_required` with no jobs for PR contexts awaiting approval/permissions.  
   **Workaround:** have a maintainer approve/enable the run, then re-run CI.
