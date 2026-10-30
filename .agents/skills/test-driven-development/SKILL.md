---
name: test-driven-development
description: Reproduce Dart behavior regressions with a failing test, fix the cause, and verify the relevant checks.
---

# Regression workflow

For a behavior change, identify the observable contract and add or adapt a
focused test before the fix where practical. Run it against the prior behavior
and check that it fails for the intended reason, rather than a setup error.
Make the smallest appropriate implementation change, then rerun that test and
the relevant checks from [CONTRIBUTING.md](../../../CONTRIBUTING.md).

A Dart test can express the boundary contract directly:

```dart
test('missing required name fails validation', () {
  final schema = Ack.object({'name': Ack.string()});
  expect(schema.safeParse({}).isFail, isTrue);
});
```

Use the real schema or generated consumer when those semantics are under test.
Mock only dependencies needed to isolate the behavior, and assert results or
side effects rather than the existence of a mock. Keep test-only helpers in tests.
Do not add production APIs solely to make a mock convenient.

A passing test added after a fix may still be useful; establish that it catches
the regression by checking the previous behavior when possible. Report what was
actually run and any unverified assumptions. Do not delete working implementation
or restart the task just to impose a particular editing order.

Docs-only edits and generated output do not need new behavior tests merely to
mirror their wording. Use existing documentation checks and regenerate outputs
through the owning tooling when that is the task.

For generator work, preserve the machine-wide concurrency and externally stopped
run rules in [AGENTS.md](../../../AGENTS.md). See
[dart-test-fundamentals](../dart-test-fundamentals/SKILL.md) for assertions and cleanup.
