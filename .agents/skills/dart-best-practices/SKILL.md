---
name: dart-best-practices
description: Apply Dart style and supported-language constraints when editing Ack Dart code.
license: Apache-2.0
---

# Dart style in Ack

Follow the package's analyzer configuration and nearby code. Use `dart format`
for Dart files and prefer multiline strings to long concatenations.
Wrap prose near 80 columns where practical; keep URLs and literal examples intact.

Check the edited package's `pubspec.yaml` before using newer syntax. The pinned
CI SDK can be newer than the minimum supported language version.
See [dart-modern-features](../dart-modern-features/SKILL.md) for feature floors.

Run the relevant checks in [CONTRIBUTING.md](../../../CONTRIBUTING.md).
