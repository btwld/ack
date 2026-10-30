---
name: dart-package-maintenance
description: Maintain Ack package versions and release documentation using the repository's coordinated release policy.
---

# Ack package maintenance

Read [PUBLISHING.md](../../../PUBLISHING.md) for version preparation and publishing,
and [CONTRIBUTING.md](../../../CONTRIBUTING.md) for checks and changelog guidance.
Check published versions before selecting a release; preserve published notes.
Normal fixes use an Unreleased section until coordinated release preparation.

All publishable packages share a version and one reviewed `v<version>` tag.
Publication follows tag verification, preflight, and the workflow approval gate.
Do not substitute local uploads or package-prefixed tags for that process.
Creating a PR does not authorize publishing, tagging, merging, or review comments.
