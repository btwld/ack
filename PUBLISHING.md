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

1. Ensure all changes are committed and pushed to the main branch
2. Verify that all tests pass by running `melos test`
3. Check that the documentation is up to date
4. Decide on the new version number following [Semantic Versioning](https://semver.org/)

### 2. Create a GitHub Release

1. Go to the [Releases page](https://github.com/btwld/ack/releases) in the repository
2. Click "Draft a new release"
3. Create a new tag in the format `v0.2.0` (must start with "v")
4. Add a title, e.g., "Release v0.2.0"
5. Add detailed release notes with the following structure:

```markdown
# Release v0.2.0

This release introduces [brief description of major changes].

## Changelog

### Breaking Changes
- **Feature**: Description of breaking change
  - Detail 1
  - Detail 2

### Improvements
- **Feature**: Description of improvement
  - Detail 1
  - Detail 2

### Bug Fixes
- Fixed [description of bug]
```

> **Important**: The content under the "## Changelog" section will be automatically added to the CHANGELOG.md files of all packages. If this section is missing or empty, the release workflow will fail.

6. Choose whether this is a pre-release:
   - Check "This is a pre-release" if you're releasing a beta or RC version
   - Pre-releases won't be published to pub.dev

7. Click "Publish release"

### 3. Automated Steps

When you publish the release, the GitHub Actions workflow will automatically:

1. Run tests and static analysis to ensure everything is working
2. Extract the version number from the tag (e.g., `v0.2.0` → `0.2.0`)
3. Extract the changelog content from the release notes
4. Update version numbers in all package pubspec.yaml files
5. Update CHANGELOG.md files with the extracted changelog content
6. Commit and push these changes back to the repository
7. Publish packages to pub.dev (unless it's marked as a pre-release)

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

1. **Missing Changelog**: Ensure your release notes contain a "## Changelog" section
2. **Empty Changelog**: The changelog section must have content
3. **Test Failures**: Fix any failing tests
4. **Permission Issues**: Ensure the GitHub Actions workflow has the necessary permissions

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
