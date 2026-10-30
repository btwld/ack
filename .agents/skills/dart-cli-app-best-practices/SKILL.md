---
name: dart-cli-app-best-practices
description: Edit Dart command-line tools and release scripts, including exit handling and process tests.
license: Apache-2.0
---

# Dart command-line tools

Use this for executable tooling, including Ack's `scripts/` directory.
Keep process entrypoints small when extracting logic makes it reusable or testable;
follow an existing script's layout rather than introducing a new package structure.

Use `exitCode` and let `main` finish when cleanup or `finally` blocks must run.
Handle expected failures with an actionable message and a nonzero status.
Preserve established exit-code contracts; do not change them as a style cleanup.

For directly executable scripts, use `#!/usr/bin/env dart` and executable mode.
Write caches under `.dart_tool/`, and give temporary outputs a cleanup path.
For HTTP tooling, identify the client with a User-Agent when the service requires it.

Prefer existing dependencies. `args` handles flags; `test_process` and
`test_descriptor` can help test real subprocess and filesystem behavior when
already appropriate to the tool. A dependency shopping list is not a requirement.

Verify observable behavior: arguments, output, exit status, and cleanup.
For release tooling, follow [PUBLISHING.md](../../../PUBLISHING.md).
