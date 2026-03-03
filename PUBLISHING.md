# Publishing Guide

This document explains how to version and publish the Ack packages to pub.dev.

## Overview

The Ack project uses GitHub Releases to manage versioning and publishing. This approach provides:

- Centralized release management through GitHub tags/releases
- Explicit version/changelog control in this repository
- Automated GitHub release notes + automated publishing to pub.dev

## Release Process

### 1. Prepare for Release

Before creating a release:

1. Ensure all changes are committed and pushed to the `main` branch
2. Verify that all tests pass by running `melos test` (include `melos run validate-jsonschema` and `melos run test:gen` for full coverage)
3. Check that the documentation is up to date across the repo and docs site
4. Decide on the new version number following [Semantic Versioning](https://semver.org/) and apply it consistently to every publishable package (`ack`, `ack_annotations`, `ack_generator`, `ack_firebase_ai`, `ack_json_schema_builder`)
5. Run `melos version --yes`. This updates versions/changelogs and runs the configured pre-commit hook (`dart scripts/update_release_changelog.dart`) so package changelogs point to release notes links for the new version/tag.

### 2. Push a Release Tag

Push the version commit and tags created by `melos version`:

```bash
git push --follow-tags
```

Supported tags:
- Stable: `v1.2.3`
- Pre-release: `v1.2.3-beta.1`, `v1.2.3-rc.1`

You can still create/edit releases manually in GitHub UI, but it is optional.

### 3. Automated Steps

When a matching tag is pushed, GitHub Actions automatically:

1. Create/update a GitHub Release with auto-generated release notes
2. Run package tests (Dart/Flutter, depending on package type)
3. Run `dart pub publish --dry-run` for each package
4. Publish each package to pub.dev

The workflow does **not** modify versions or commit back to the repository.

### 4. Verify the Release

After the workflow completes:

1. Check that the packages are available on pub.dev
2. Verify that the version numbers and changelogs are correct
3. Test the published packages in a new project to ensure they work as expected

## Alternative: Manual Versioning

If needed, you can version packages locally from conventional commits:

```bash
# Propose/apply version and changelog updates
melos version

# Non-interactive
melos version --yes

# Push the version commit and tags (triggers release notes + pub publish)
git push --follow-tags
```

## Manual Publishing

If you need to publish packages manually:

```bash
# Dry-run each package (validation only)
for pkg in ack ack_annotations ack_generator ack_json_schema_builder ack_firebase_ai; do
  (cd packages/$pkg && dart pub publish --dry-run) || exit 1
done

# Actual publish (no dry-run)
melos run publish
```

## Troubleshooting

### Release Workflow Fails

If the release workflow fails, check:

1. **Test Failures**: Fix any failing tests or analyze issues
2. **Version Issues**: Check if the version is valid and follows semantic versioning
3. **Permission Issues**: Ensure the GitHub Actions workflow has the necessary permissions
4. **Git Issues**: There might be problems with pushing commits back to the repository

### Manual Publishing Issues

If manual publishing fails:

1. **Authentication**: Ensure you're logged in to pub.dev with `dart pub login`
2. **Version Conflicts**: Check if the version already exists on pub.dev
3. **Dependency Issues**: Verify that all dependencies are correctly specified

## Version Numbering

The Ack project follows [Semantic Versioning](https://semver.org/):

- **Major version (x.0.0)**: Incompatible API changes
- **Minor version (0.x.0)**: Backwards-compatible functionality additions
- **Patch version (0.0.x)**: Backwards-compatible bug fixes

For pre-releases, use formats like `0.2.0-beta.1` or `0.2.0-rc.1`.
