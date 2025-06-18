# API Compatibility Reference

> **Note**: For complete development workflows, see [DEVELOPMENT.md](../../DEVELOPMENT.md)

## 🚀 Command Reference

### Daily Development
```bash
# Check changes during development (warnings only)
melos api-check:dev

# Create/check local baseline
melos api:baseline:create
melos api:baseline:check

# Compare against specific tag
melos api:compare --TAG=v0.2.0
melos api:vs-last  # Compare against last tag
```

### Before Release
```bash
# Compare against specific version (strict)
melos api:compare:strict --TAG=v0.3.0-beta.1

# Comprehensive pre-release validation
melos api:pre-release

# Final strict check
melos api:release:check

# Generate detailed report
melos api-report
```

### Tag Management
```bash
# List available tags
melos api:tags

# Quick comparison against last tag
melos api:vs-last
melos api:vs-last:strict
```

## 🎯 Command Modes

| Command | Mode | Fails CI? | Use Case |
|---------|------|-----------|----------|
| `api-check:dev` | Lenient | ❌ No | Daily development |
| `api:compare --TAG=v0.2.0` | Lenient | ❌ No | Compare vs specific tag |
| `api:compare:strict --TAG=v0.2.0` | Strict | ✅ Yes | Strict tag comparison |
| `api:vs-last` | Lenient | ❌ No | Quick last tag check |
| `api:vs-last:strict` | Strict | ✅ Yes | Strict last tag check |
| `api:release:check:dev` | Warnings | ❌ No | PR reviews |
| `api:release:check` | Strict | ✅ Yes | Final validation |
| `api:pre-release` | Comprehensive | ⚠️ Conditional | Pre-release check |

## 📋 Quick Workflows

### 🔧 Development: `baseline → change → check → repeat`
### 🚀 Release: `pre-release → review → final-check → tag`

> **Detailed workflows**: See [DEVELOPMENT.md](../../DEVELOPMENT.md#api-compatibility-maintainers)

## 🔍 Understanding Reports

### CLI Output Symbols
- ✅ **Green**: Non-breaking changes (safe)
- ⚠️ **Yellow**: Minor version bump needed
- ❌ **Red**: Major version bump required
- 📋 **Blue**: Informational changes

### Version Bump Guide
| Change Type | Pre-1.0 (0.x.x) | Post-1.0 (1.x.x) |
|-------------|------------------|-------------------|
| Bug fixes | 0.3.0 → 0.3.1 | 1.0.0 → 1.0.1 |
| New features | 0.3.0 → 0.4.0 | 1.0.0 → 1.1.0 |
| Breaking changes | 0.3.0 → 0.4.0 | 1.0.0 → 2.0.0 |

## 🛠️ Troubleshooting

### "No previous release found"
- **First release**: Normal, creates baseline
- **Missing tags**: Check `git tag -l`
- **Unpublished package**: Use local baseline workflow

### "Breaking changes detected"
- **Pre-1.0**: Review and proceed if intentional
- **Post-1.0**: Ensure proper version bump
- **False positive**: Check specific changes in report

### CI Failing
- **PR**: Should never fail (check configuration)
- **Main**: Review breaking changes, update version
- **Release**: Validate changes match version increment

## 📚 File Locations

### Generated Files
- `api-compatibility-report.md` - Standard report
- `pre-release-validation-report.md` - Pre-release report
- `api-baseline-*.json` - API baselines
- `api-diff-*.md` - CI-generated reports

### Configuration Files
- `.github/workflows/ci.yml` - CI configuration
- `melos.yaml` - Melos scripts
- `tools/api-baseline.sh` - Helper script

## 🎯 Best Practices Summary

1. **Use development mode** during active development
2. **Switch to strict mode** before releases
3. **Review generated reports** for change details
4. **Update CHANGELOG.md** with breaking changes
5. **Create migration guides** for major changes
6. **Test with real projects** before releasing breaking changes

## 🔗 Quick Links

- **[Development Guide](../../DEVELOPMENT.md)** - Complete workflows and setup
- **[dart_apitool Package](https://pub.dev/packages/dart_apitool)** - Official tool documentation
- **[Semantic Versioning](https://semver.org/)** - Version strategy guide
- **[Melos Commands](../../melos.yaml)** - All available scripts
