# Contributing to Ack

Thanks for helping improve Ack. Keep changes focused, tested, and easy to
review. By participating, you agree to follow the
[Code of Conduct](./CODE_OF_CONDUCT.md).

## Development setup

The workspace uses Flutter `3.50.0-0.1.pre` / Dart `3.14.0-315.1.beta`.
Install/select the SDK pinned by `.fvmrc` before running commands (for example,
`fvm use` and `fvm dart ...`). Do not use a global older Dart SDK.
The analyzer configuration and Melos commands enable experimental augmentations.

Melos requires a globally activated CLI matching the exact workspace version.
`./setup.sh` performs the setup below and installs optional Node tooling when
npm is available. To set up manually:

```bash
dart pub get
dart pub global activate melos 8.9.0
dart pub global run melos bootstrap
```

Ack uses a Melos workspace. Run commands from the repository root unless a
package README says otherwise. Use `dart pub global run melos ...` so the
activated CLI does not need to be on `PATH`.

Use `dart pub global run melos run format` to format authored sources. The beta
SDK's formatter does not preserve `augment` declarations, so this command
excludes generated `.g.dart` files. The generator formats those files itself;
CI checks them by regenerating from a clean tree.

## Before opening a PR

1. Keep the change scoped to one problem.
2. Add or update tests for behavior changes.
3. Update docs or README snippets when public APIs, examples, or setup steps
   change.
4. Run the relevant checks:

```bash
dart pub global run melos run analyze
dart pub global run melos run test
```

For code generation changes, also run:

```bash
dart pub global run melos run test:gen
```

The generator suite is memory-heavy: nine tests tagged `integration` run
real `build_runner` builds in temporary packages. For a quick check while
iterating, skip them:

```bash
dart pub global run melos run test:gen:unit
```

Run the full `test:gen` before opening the PR. Run one generator suite at a
time on a machine; running it from several checkouts in parallel can exhaust
memory.
Tag any new test that runs a real `build_runner` build with
`@Tags(['integration'])`.

For JSON Schema export changes, also run:

```bash
dart pub global run melos run validate-jsonschema
```

## Commit style

Use Conventional Commits, for example:

```text
feat(ack): add schema helper
fix(generator): preserve nullable list getters
docs: clarify codec examples
```

Use `!` or a `BREAKING CHANGE:` footer for breaking API changes.

## Release notes

User-facing changes should update the relevant package `CHANGELOG.md`. Release
publishing is handled by maintainers through `PUBLISHING.md`.

## Getting help and reporting security issues

Use [SUPPORT.md](./SUPPORT.md) for questions and public bug reports. Follow
[SECURITY.md](./SECURITY.md) for vulnerabilities; do not disclose suspected
security issues in a public issue.
