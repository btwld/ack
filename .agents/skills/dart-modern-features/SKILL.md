---
name: dart-modern-features
description: Choose modern Dart syntax that fits the edited Ack package's minimum SDK.
---

# Modern Dart within the supported SDK

Read the edited package's `pubspec.yaml` first. Do not raise its minimum SDK
for a cosmetic refactor. A newer local or pinned CI SDK does not change the
consumer language floor.

| Feature | Minimum Dart | Useful when |
|---|---|---|
| Records | 3.0 | Returning a few related values without a public named type |
| Patterns and switch expressions | 3.0 | Destructuring values and checking sealed alternatives exhaustively |
| Class modifiers | 3.0 | Expressing intended inheritance and implementation boundaries |
| Extension types | 3.3 | A representation wrapper with the required runtime semantics |
| Digit separators | 3.6 | Making long numeric literals readable |
| Wildcard variables | 3.7 | Declaring intentionally unused bindings |
| Null-aware collection elements | 3.8 | Including a value only when non-null |
| Dot shorthand | 3.10 | Omitting an obvious enum/static qualifier |

Use explicit enum and static qualifiers in packages whose SDK lower bound is
Dart 3.9. Dot shorthand requires an SDK lower bound of **>=3.10**, even when
the local or CI SDK is newer.

Use a named type when its identity or API matters; records are not a blanket
replacement for classes. An extension type is not an immutable model class.
Keep existing exhaustive switches meaningful when adding variants.

Ack 2.0 retains stable-Dart generated mixins and facades. Do not reintroduce
experimental augmentations without an approved toolchain migration; see
[the decision log](../../../ARCHITECTURE.md#stable-dart-for-20).
