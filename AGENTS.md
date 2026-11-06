# Agent notes

Follow [CONTRIBUTING.md](CONTRIBUTING.md), including its generator-test
notes. Use the branch-local [API index](llms.txt) for task-specific docs and
[PUBLISHING.md](PUBLISHING.md) for release work.

- Never run the `ack_generator` suite from several checkouts or worktrees at
  the same time.
- Don't restart a test run that was stopped from outside; ask first.

The generator constraint follows the memory incident in
[PR #179](https://github.com/btwld/ack/pull/179).
