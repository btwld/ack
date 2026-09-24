# Publishing Guide

ACK uses a coordinated release: all six publishable packages share one version
and a single `v<version>` tag. GitHub Actions publishes dependencies before their
consumers using pub.dev OIDC credentials and the protected `Production`
environment. A release-preparation PR does not publish anything.

## Version policy

Use SemVer for the combined public API: patch for compatible fixes, minor for
new compatible features/packages, and major when any stable public API breaks.
The next release is **1.6.2**, restoring JSON Schema import compatibility for
`pattern` and accepting standard `propertyNames` schemas. No public Dart API
was added; this is a patch release for the import compatibility fix. The API
check compares the six packages against v1.6.1.

The shared API baseline for this release is 1.6.1. Confirm that all six
packages have published 1.6.1 versions before preparing the release.

Melos **8.7** is configured with `mode: fixed` and `workspaceTag: true`, matching
this repository's release-tag verifier. `smartDependents: true` preserves
compatible dependency minimums instead of forcing unnecessary upgrades.
For example, packages at 1.3.0 can still declare `ack: ^1.2.0` when they use only
1.2 APIs. Raise that minimum when a consumer actually requires a newer API.

Pub workspaces manage one local dependency resolution, not package versions.
Keep hosted version constraints on sibling dependencies and `resolution:
workspace` in members; do not add local path overrides to publishable manifests.
Keep explicit workspace paths because glob patterns require Dart 3.11 and this
repository supports Dart 3.9. The root and `ack_example` are private and are not
part of the six-package release.

References: [Melos versioning](https://melos.invertase.dev/commands/version),
[pub workspaces](https://dart.dev/tools/pub/workspaces), and
[pub versioning](https://dart.dev/tools/pub/versioning).

## Prepare a release PR

1. Check pub.dev and tags before selecting the version; published versions and
   their changelog sections are immutable.
2. Start a release branch from current `origin/main` and resolve dependencies:

   ```sh
   dart pub get
   ```

3. Preview/prepare a coordinated version without creating commits or tags:

   ```sh
   dart run melos version --manual-version=ack:1.6.2 --yes --no-git-commit-version
   ```

   Use the named flag, not a positional package argument: the positional form
   filters the selected packages in Melos 8.7. Choose the next SemVer value for
   later releases. Normal automatic selection is also available with
   `dart run melos version --yes --no-git-commit-version` after reviewing commits.
   Do not pass `--all`: that would include private packages.

4. Review generated changelogs and retain substantive release notes; move only
   unreleased notes into the new section, preserving every published section.
   Update installation snippets to match each package's version.
5. Set `API_BASELINE_VERSION` in `.github/workflows/preflight.yml` to the latest
   release published for all packages (currently `1.6.1`). Record a new
   package's actual first release in `ackPackageFirstReleases` in
   `scripts/src/workspace_packages.dart`;
   checks skip only older baselines. `ack_mcp_dart` first released at 1.3.0.
6. Validate the complete release:

   ```sh
   dart scripts/verify_release_tag.dart v1.6.2 --skip-ancestry
   dart run melos run ci
   dart scripts/api_check.dart 1.6.1
   dart scripts/publish_dry_run.dart
   dart run melos run validate-jsonschema:batch
   ```

   `--skip-ancestry` is only for preparing a version before the tag exists.
   The actual release workflow always enforces ancestry on `origin/main`.
   CI also runs minimum Dart/Flutter SDK checks, deterministic generation, and
   staged hosted-dependency analysis; all must pass on the release merge commit.
7. Review and merge the release PR before creating the tag.

## Historical first publication of ack_mcp_dart

[pub.dev requires the first version of a new package to be published manually](https://dart.dev/tools/pub/automated-publishing).
OIDC cannot create a new package. The steps below applied only to the first
`ack_mcp_dart` release, v1.3.0; do not repeat them for 1.6.2.

After the release PR merges and all checks pass, but **before pushing v1.3.0**:

1. Check out the reviewed release commit and stage the new package outside the
   workspace so its hosted dependencies are verified:

   ```sh
   dart scripts/stage_package.dart ack_mcp_dart /tmp/ack-mcp-first-release
   cd /tmp/ack-mcp-first-release/packages/ack_mcp_dart
   dart pub get
   dart analyze --fatal-infos
   dart test
   dart pub publish --dry-run
   dart pub publish
   ```

   It declares `ack: ^1.2.0`, so the first upload can resolve the already-published
   core package. Follow pub's authentication prompt using an authorized uploader
   account; for a supported token-based flow use `dart pub token add https://pub.dev`.
2. In the package's pub.dev Admin tab, enable GitHub Actions publication for
   repository `btwld/ack`, tag pattern `v{{version}}`, and required
   environment `Production`. Associate the package with the intended publisher.
3. Verify version 1.3.0 is visible on pub.dev before starting the coordinated tag
   release. Keep the same reviewed source for the manual upload and release tag.

Later releases need no manual package bootstrap. Existing package Admin settings
must likewise permit the repository/tag/environment used by the workflow; the
repository cannot configure pub.dev Admin settings on behalf of its owner.

## Publish the coordinated release

After the release commit's CI/preflight succeeds:

```sh
git fetch origin main --tags
# Use the exact reviewed release merge commit, not an arbitrary later main head.
git tag -a v1.6.2 <release-merge-sha> -m 'Ack 1.6.2'
dart scripts/verify_release_tag.dart v1.6.2
git push origin v1.6.2
```

Pushing the tag triggers `.github/workflows/release.yml`; there is no Melos
publish/release script. The workflow verifies the tag, reruns release preflight,
and publishes in dependency order:

1. `ack`, `ack_annotations`
2. `ack_generator`
3. `ack_json_schema_builder`, `ack_mcp_dart`, `ack_firebase_ai`

Each package resolves and analyzes a staged copy against pub.dev, runs tests,
and passes a zero-warning publish dry run. `dart-lang/setup-dart` provisions the
short-lived OIDC credential immediately before upload; no permanent `PUB_TOKEN`
secret is required. Approve the existing `Production` environment deployment
when GitHub requests it.

The workflow checks exact versions on pub.dev and skips upload/OIDC provisioning
for versions already published, while retaining validation. This handles the
manually bootstrapped MCP adapter and retries after a partially completed
release. Network/server failures stop the job instead of being mistaken for a
missing version. Rerun failed jobs on the **same tag**; never move a published tag
or republish different contents under an existing version.

After all six exact versions are visible, create the GitHub Release from the
existing tag using the prepared release notes. Before the first subsequent code
change, begin a new unreleased changelog section instead of editing 1.6.2 notes.
