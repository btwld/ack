# Ack Validation Workspace

[![CI/CD](https://github.com/leoafarias/ack/actions/workflows/ci.yml/badge.svg)](https://github.com/leoafarias/ack/actions/workflows/ci.yml)
[![docs.page](https://img.shields.io/badge/docs.page-documentation-blue)](https://docs.page/leoafarias/ack)

This is a monorepo containing packages for the Ack validation ecosystem.

## Packages

- **[ack](./packages/ack)**: A fluent schema-building and validation library for Dart.
- **[ack_generator](./packages/ack_generator)**: Code generator that creates validation schema classes from annotated Dart classes.
- **[example](./example)**: Demonstrates usage of `ack` and `ack_generator`.

## Documentation

Detailed documentation is available at [docs.page/leoafarias/ack](https://docs.page/leoafarias/ack).

## Development

This project uses [Melos](https://github.com/invertase/melos) to manage the monorepo.

### Setup

```bash
# Install Melos (if not already installed)
dart pub global activate melos

# Bootstrap the workspace (installs dependencies for all packages)
melos bootstrap
```

### Common Commands (run from root)

```bash
# Run tests across all packages
melos test

# Format code across all packages
melos format

# Analyze code across all packages
melos analyze

# Check for outdated dependencies
melos deps-outdated

# Run build_runner for packages that need it (e.g., ack_generator, example)
melos build

# Clean build artifacts
melos clean

# Bump patch version (0.0.x)
melos version-patch

# Bump minor version (0.x.0)
melos version-minor

# Bump major version (x.0.0)
melos version-major

# Dry-run publish (validation only)
melos publish-dry

# Publish packages to pub.dev
melos publish
```

## Versioning and Publishing

This project uses GitHub Releases to manage versioning and publishing.

### How to Release a New Version

#### Using GitHub Releases (Recommended)

1. Go to the "Releases" tab in the repository
2. Click "Draft a new release"
3. Create a new tag in the format `v1.2.3` (must start with "v")
4. Write a title for your release
5. Add detailed release notes in the description
   - These notes will be added to the CHANGELOG.md files
   - Use Markdown formatting for better readability
6. Choose whether this is a pre-release or not
   - Pre-releases won't be published to pub.dev
7. Click "Publish release"

This will automatically:
- Run tests and static analysis to ensure everything is working properly
- Update version numbers in all package pubspec.yaml files
- Update CHANGELOG.md files with your release notes
- Create git tags
- Publish to pub.dev (unless it's a pre-release)

#### Alternative: Local Versioning

You can also version packages locally if needed:

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

### Manual Publishing

If you need to publish packages manually:

```bash
# Dry run (validation only)
melos publish-dry

# Actual publish
melos publish
```

## Contributing

Contributions are welcome! A detailed CONTRIBUTING.md file will be added soon with specific guidelines.

In the meantime, please follow these basic steps:
1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Run tests with `melos test`
5. Make sure to follow [Conventional Commits](https://www.conventionalcommits.org/) in your commit messages
6. Submit a pull request
