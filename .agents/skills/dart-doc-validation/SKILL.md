---
name: dart-doc-validation
description: Validate Dart documentation comments for unresolved references and undefined macros.
license: Apache-2.0
---

# Dart documentation validation

When editing `///` references or macros, run this from the owning package:

```bash
dart doc -o "$(mktemp -d)"
```

Resolve warnings about `[Identifier]` references using names visible in scope.
Check that `{@macro name}` has an accessible matching `{@template name}`.
Remove the temporary output after inspection.

This checks Dart API comments. For MDX pages, use the documentation check in
`.github/workflows/docs.yml` and relevant existing documentation tests.
