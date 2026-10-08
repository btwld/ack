# Publishing Guide

ACK uses a coordinated release: all five publishable packages share one version
and a single `v<version>` tag. GitHub Actions publishes dependencies before their
consumers using pub.dev OIDC credentials and the protected `Production`
environment. A release-preparation PR does not publish anything.

## Version policy

Use SemVer for the combined public API: patch for compatible fixes, minor for
new compatible features/packages, and major when any stable public API breaks.
For 1.7.0, the imported-pattern Unicode behavior change is a deliberately
accepted exception to this major-version policy.

The next candidate is **1.7.0-beta.7**. It adds `multipleOf` validation,
built-in string and numeric `format` assertions, `x-*` vendor extension
annotation tolerance, and Draft-07 `$schema` URI support to strict JSON Schema
import (`Ack.fromJsonSchema()`).
The beta.5 imported-pattern change to ECMA-262 Unicode mode still applies when
upgrading from stable 1.6.2 or earlier 1.7.0 betas; review imported patterns,
including identity escapes and expressions that count UTF-16 code units. Native
`Ack.string().matches()` keeps its Dart regex contract. The beta.3 annotation
and generator migration still applies to consumers coming from earlier
versions; beta.7 adds no new generator migration. The API check compares all
five packages against 1.6.2; generator compatibility also requires the consumer
build and runtime tests because the API check cannot inspect generated consumer
code.

The shared API baseline for this release is 1.6.2. Confirm that all five
packages have published 1.6.2 versions before preparing the release.

Melos **8.x** is configured with `mode: fixed` and `workspaceTag: true`, matching
this repository's release-tag verifier. `smartDependents: true` preserves
compatible dependency minimums instead of forcing unnecessary upgrades.
For example, packages at 1.3.0 can still declare `ack: ^1.2.0` when they use only
1.2 APIs. Raise that minimum when a consumer actually requires a newer API.

Pub workspaces manage one local dependency resolution, not package versions.
Keep hosted version constraints on sibling dependencies and `resolution:
workspace` in members; do not add local path overrides to publishable manifests.
Keep explicit workspace paths because glob patterns require Dart 3.11 and this
repository supports Dart 3.9. The root and `ack_example` are private and are not
part of the five-package release.

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
   dart run melos version --manual-version=ack:1.7.0-beta.7 --yes --no-git-commit-version
   ```

   Use the named flag, not a positional package argument: the positional form
   selects a package instead of requesting a coordinated version. Choose the
   next SemVer value for later releases. Normal automatic selection is also available with
   `dart run melos version --yes --no-git-commit-version` after reviewing commits.
   Do not pass `--all`: that would include private packages. Melos fetches tags
   through Git; a new local branch needs an upstream before this command runs.

4. Review generated changelogs and retain substantive release notes; move only
   unreleased notes into the new section, preserving every published section.
   Update installation snippets to match each package's version.
5. Compare against the most recent coordinated stable release in
   `API_BASELINE_VERSION` in `.github/workflows/preflight.yml` (currently
   `1.6.2`). Keep that stable baseline for prereleases, so a beta cannot hide a
   breaking change since the last stable version. Raise it after the next
   stable release. Record a new
   package's actual first release in `ackPackageFirstReleases` in
   `scripts/src/workspace_packages.dart`;
   checks skip only older baselines. `ack_mcp_dart` first released at 1.3.0.
6. Commit the reviewed version, changelog, and documentation changes locally
   before the publish dry run. Pub treats modified tracked package files as a
   warning, and this repository requires zero warnings.
7. Validate the complete release from that clean commit:

   ```sh
   dart scripts/verify_release_tag.dart v1.7.0-beta.7 --skip-ancestry
   dart run melos run ci
   dart scripts/api_check.dart 1.6.2
   dart scripts/publish_dry_run.dart
   dart run melos run validate-jsonschema:batch
   ```

   `--skip-ancestry` is only for preparing a version before the tag exists.
   The actual release workflow always enforces ancestry on `origin/main`.
   CI also runs minimum Dart/Flutter SDK checks, deterministic generation, and
   staged hosted-dependency analysis; all must pass on the release merge commit.
8. Review and merge the release PR before creating the tag.

## Historical first publication of ack_mcp_dart

[pub.dev requires the first version of a new package to be published manually](https://dart.dev/tools/pub/automated-publishing).
OIDC cannot create a new package. The steps below applied only to the first
`ack_mcp_dart` release, v1.3.0; do not repeat them for later releases.

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
git tag -a v1.7.0-beta.7 <release-merge-sha> -m 'Ack 1.7.0 beta 7'
dart scripts/verify_release_tag.dart v1.7.0-beta.7
git push origin v1.7.0-beta.7
```

Pushing the tag triggers `.github/workflows/release.yml`; there is no Melos
publish/release script. The workflow verifies the tag, reruns release preflight,
and publishes in dependency order:

1. `ack`
2. `ack_generator`
3. `ack_json_schema_builder`, `ack_mcp_dart`, `ack_firebase_ai`

Each package resolves and analyzes a staged copy against pub.dev, runs tests,
and passes a zero-warning publish dry run. `dart-lang/setup-dart` provisions the
short-lived OIDC credential immediately before upload; no permanent `PUB_TOKEN`
secret is required. The workflow pauses once, after preflight, at the
`Release` environment; approve that deployment to publish every package.
`Production` keeps its `v*` tag policy for pub.dev OIDC but has no reviewers,
so the publish stages do not ask again.

The workflow checks exact versions on pub.dev and skips upload/OIDC provisioning
for versions already published, while retaining validation. This handles the
manually bootstrapped MCP adapter and retries after a partially completed
release. Network/server failures stop the job instead of being mistaken for a
missing version. Rerun failed jobs on the **same tag**; never move a published tag
or republish different contents under an existing version.

After all five exact versions are visible, create the GitHub Release from the
existing tag using the prepared release notes and mark it as a prerelease for
beta versions. Before the first subsequent code
change, begin a new unreleased changelog section instead of editing the
1.7.0-beta.7 notes.
