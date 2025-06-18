# Development Guide

This document provides development guidelines and workflows for Ack library maintainers and contributors.

## 🚀 Quick Setup

### Prerequisites
- Dart SDK 3.3.0+
- Melos for monorepo management
- Git for version control

### Initial Setup
```bash
# Install Melos globally
dart pub global activate melos

# Bootstrap the workspace
melos bootstrap

# Install development tools
dart pub global activate dart_apitool
```

## 📋 Development Workflows

### Daily Development
```bash
# Start development session
melos bootstrap

# Run tests during development
melos test

# Check code quality
melos analyze
melos format

# Before committing
melos test
melos analyze
```

### API Compatibility (Maintainers)

We use [dart_apitool](https://pub.dev/packages/dart_apitool) to track API changes and ensure semantic versioning compliance.

#### Quick Commands
```bash
# Daily development (warnings only)
melos api-check:dev
melos api:baseline:create
melos api:baseline:check

# Tag comparisons
melos api:vs-last                    # Compare against last tag
melos api:compare --TAG=v0.2.0      # Compare against specific tag

# Before releases (strict)
melos api:pre-release               # Comprehensive validation
melos api:release:check             # Final strict check
```

#### What dart_apitool Tracks
- ✅ Method signature changes (parameters, return types)
- ✅ Class hierarchy modifications (inheritance, interfaces)
- ✅ Visibility changes (public ↔ private)
- ✅ Required parameter additions
- ✅ Type constraint changes
- ❌ Implementation-level changes (not detected)

#### Pre-1.0 Strategy (Current: 0.3.0-beta.1)
- **Development**: Use lenient mode (`api-check:dev`) - warnings only
- **Releases**: Use strict mode (`api:release:check`) - fails on breaking changes
- **Breaking changes allowed** in minor versions (0.2.0 → 0.3.0) per semver

### Code Generation
```bash
# Run code generation for packages that need it
melos build

# Clean generated files
melos clean
```

## 🔧 Available Scripts

### Core Development
- `melos test` - Run tests across all packages
- `melos analyze` - Analyze code across all packages
- `melos format` - Format code across all packages
- `melos build` - Run build_runner for code generation
- `melos clean` - Clean build artifacts

### Quality Assurance
- `melos validate-jsonschema` - Validate JSON Schema compatibility
- `melos api-check:dev` - Check API compatibility (development mode)
- `melos deps-outdated` - Check for outdated dependencies

### Release Management
- `melos version` - Interactive version bumping
- `melos publish` - Publish packages to pub.dev

## 📚 Documentation

### Public Documentation
- **Location**: `docs/` directory
- **Published to**: [docs.page/btwld/ack](https://docs.page/btwld/ack)
- **Format**: MDX files for docs.page
- **Purpose**: User-facing documentation, guides, API reference

### Internal Documentation
- **Location**: `tools/docs/` directory
- **Not published**: Internal use only
- **Format**: Markdown files
- **Purpose**: Development workflows, internal tools, maintainer guides

## 🎯 Code Quality Standards

### Testing
- All new features must include tests
- Maintain test coverage above 80%
- Run `melos test` before committing

### Code Style
- Follow Dart style guidelines
- Use `melos format` to format code
- Address all analyzer warnings with `melos analyze`

### API Design
- Follow semantic versioning strictly
- Use API compatibility checking for releases
- Document breaking changes in CHANGELOG.md

## 🚀 Release Process

### Pre-Release Checklist
1. Run full test suite: `melos test`
2. Check API compatibility: `melos api:pre-release`
3. Update CHANGELOG.md with changes
4. Verify documentation is up to date

### Release Steps
1. Create release branch: `git checkout -b release/v0.x.x`
2. Bump versions: `melos version`
3. Final validation: `melos api:release:check`
4. Create PR and get approval
5. Merge to main and tag release
6. GitHub Actions will handle publishing

## 🛠️ Troubleshooting

### Common Issues

#### Melos Bootstrap Fails
```bash
# Clean and retry
melos clean
dart pub cache repair
melos bootstrap
```

#### Code Generation Issues
```bash
# Clean and rebuild
melos clean
melos build
```

#### API Compatibility Errors
```bash
# Check what changed
melos api:baseline:check

# Generate detailed report
melos api:baseline:report
```

### Getting Help
- Check `tools/docs/` for detailed internal documentation
- Run `melos list-scripts` to see all available commands
- Review CI logs for automated checks

## 📞 Maintainer Resources

### Internal Tools
- **API Compatibility**: See [`tools/docs/API_REFERENCE.md`](tools/docs/API_REFERENCE.md) for command reference
- **JSON Schema Validation**: See [`tools/README.md`](tools/README.md)
- **Development Scripts**: See [`melos.yaml`](melos.yaml)

### External Resources
- [Melos Documentation](https://melos.invertase.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

> **Note**: This guide covers general development workflows. For detailed information about specific tools and processes, see the documentation in `tools/docs/`.
