# Contributing to Ack

Thanks for helping improve Ack. Keep changes focused, tested, and easy to
review.

## Development setup

```bash
dart pub global activate melos
melos bootstrap
```

Ack uses a Melos workspace. Run commands from the repository root unless a
package README says otherwise.

## Before opening a PR

1. Keep the change scoped to one problem.
2. Add or update tests for behavior changes.
3. Update docs or README snippets when public APIs, examples, or setup steps
   change.
4. Run the relevant checks:

```bash
melos analyze
melos test
```

For code generation changes, also run:

```bash
melos run test:gen
```

For JSON Schema export changes, also run:

```bash
melos run validate-jsonschema
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
