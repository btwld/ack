# Agent notes

Follow [CONTRIBUTING.md](CONTRIBUTING.md). One rule matters for machine
resources:

- `ack_generator` tests are memory-heavy. Its integration tests run real
  `build_runner` builds in temporary packages. Use
  `dart run melos run test:gen:unit` while iterating, and run the full
  `dart run melos run test:gen` once before finishing. Never run the
  generator suite from several checkouts or worktrees at the same time, and
  don't restart a test run that was stopped from outside; ask first.
