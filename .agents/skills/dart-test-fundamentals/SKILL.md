---
name: dart-test-fundamentals
description: Write Ack package:test tests with useful assertions, cleanup, async sequencing, and generator resource limits.
license: Apache-2.0
---

# Dart tests and assertions

Use a descriptive `_test.dart` file under `test/`. Name tests for observable
behavior and group related cases where shared setup helps.
Use `setUp`/`tearDown` for mutable fixtures; register temporary-file and process
cleanup so failures do not leave state behind.

Prefer assertions that explain failures:

```dart
expect(values, hasLength(2));
expect(values, contains('expected'));
expect(result, isA<Ok<String>>().having((r) => r.value, 'value', 'expected'));
expect(() => parseInvalid(), throwsA(isA<AckException>()));
await expectLater(loadValue(), completion('expected'));
```

The names in the example are illustrative. Match the actual API and error
contract; avoid testing only that a result is non-null or that a mock exists.
Use `unorderedEquals` when order does not matter, `containsPair` for maps,
and `.having` to name the property that failed. Await asynchronous assertions
before checking dependent side effects.

Run from the owning package when targeting a file:

```bash
dart test test/path_to_test.dart
```

Use [CONTRIBUTING.md](../../../CONTRIBUTING.md) for root Melos checks.
Generator runs are memory-heavy: run one suite per machine at a time and do not
restart a run stopped from outside without asking. Tag real temporary-package
`build_runner` builds with `@Tags(['integration'])`; use `test:gen:unit` while
iterating and the full generator check for generator changes before a PR.

Keep concurrency and tags in `packages/ack_generator/dart_test.yaml`.
For other configuration keys, including `timeout`, use the
[package:test configuration reference](https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md).
For regression workflow, see
[test-driven-development](../test-driven-development/SKILL.md).
