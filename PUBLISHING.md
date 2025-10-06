# Publishing Guide

This document explains how to version and publish the Ack packages to pub.dev.

## Overview

The Ack project uses GitHub Releases to manage versioning and publishing. This approach provides:

- Centralized release management through GitHub's UI
- Automatic version updates across all packages
- Automatic changelog generation from release notes
- Automated publishing to pub.dev

## Release Process

### 1. Prepare for Release

Before creating a release:

1. Ensure all changes are committed and pushed to the `main` branch
2. Verify that all tests pass by running `melos test` (include `melos run validate-jsonschema` and `melos run test:gen` for full coverage)
3. Check that the documentation is up to date across the repo and docs site
4. Decide on the new version number following [Semantic Versioning](https://semver.org/) and apply it consistently to every publishable package (`ack`, `ack_annotations`, `ack_generator`)
5. The version hook automatically rewrites the newest changelog entry to a single “See release notes” link. If you need to regenerate it manually, run `dart scripts/update_release_changelog.dart <version> <yyyy-mm-dd>` after `melos version`.

### 2. Create a GitHub Release

1. Go to the [Releases page](https://github.com/btwld/ack/releases) in the repository
2. Click "Draft a new release"
3. Create a new tag in the format `v0.2.0` (must start with "v")
4. Add a title, e.g., "Release v0.2.0"
5. Add detailed release notes with a structure like:

```markdown
# Release v0.2.0

This release introduces [brief description of major changes].

## Key Features
- **Feature 1**: Description
- **Feature 2**: Description

## Breaking Changes
- **Feature**: Description of breaking change
  - Detail 1
  - Detail 2

## Improvements
- **Feature**: Description of improvement
  - Detail 1
  - Detail 2

## Bug Fixes
- Fixed [description of bug]
```

> **Note**: You should manually update the CHANGELOG.md files in each package before creating a release. The release workflow will no longer automatically extract content from release notes to update changelogs.

6. Choose whether this is a pre-release:
   - Check "This is a pre-release" if you're releasing a beta or RC version
   - Pre-releases WILL be published to pub.dev as pre-release versions
   - Only draft releases won't be published to pub.dev

7. Click "Publish release"

### 3. Automated Steps

When you publish the release, the GitHub Actions workflow will automatically:

1. Run tests and static analysis to ensure everything is working
2. Extract the version number from the tag (e.g., `v0.2.0` → `0.2.0`)
3. Update version numbers in all package pubspec.yaml files
4. Add a simple changelog entry to each package's CHANGELOG.md with a link to the GitHub release
5. Commit and push these changes back to the repository
6. Publish packages to pub.dev (both regular releases and pre-releases, but not drafts)

The auto-generated changelog entry will look like:

```markdown
## 0.2.0 (2025-05-03)

* See [release notes](https://github.com/btwld/ack/releases/tag/v0.2.0) for details.
```

This ensures your changelogs meet pub.dev requirements while directing users to your detailed release notes.

### 4. Verify the Release

After the workflow completes:

1. Check that the packages are available on pub.dev
2. Verify that the version numbers and changelogs are correct
3. Test the published packages in a new project to ensure they work as expected

## Alternative: Manual Versioning

If needed, you can also version packages locally:

```bash
# Bump patch version (0.0.x)
melos version-patch

# Bump minor version (0.x.0)
melos version-minor

# Bump major version (x.0.0)
melos version-major

# Push the changes and tags
git push --follow-tags
```

## Manual Publishing

If you need to publish packages manually:

```bash
# Dry run (validation only)
melos publish-dry

# Actual publish
melos publish
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
