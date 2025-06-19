# API Compatibility Reference

> **Note**: For complete development workflows, see [DEVELOPMENT.md](../../DEVELOPMENT.md)

## 🚀 Single Command API Check

The Ack project now uses a simplified single Dart script for API compatibility checking:

```bash
# Check API compatibility for all packages against a specific tag
melos api-check v0.2.0
```

### What it does:
- ✅ Checks both `ack` and `ack_generator` packages
- ✅ Compares against the specified git tag version  
- ✅ Generates separate markdown reports for each package
- ✅ Reports are automatically saved and gitignored

### Direct Script Usage:
```bash
# Use the Dart script directly
dart scripts/api_check.dart v0.2.0                 # Check all packages
dart scripts/api_check.dart ack v0.2.0             # Check specific package  
dart scripts/api_check.dart ack                    # Check against latest
```

### Example Output:
```bash
🚀 API Compatibility Check vs v0.2.0
📦 Checking ack package...
✅ ack: API check completed
📄 Report saved: api-compat-ack-vs-v0.2.0.md

📦 Checking ack_generator package...
⚠️  ack_generator: API changes detected
📄 Report saved: api-compat-ack_generator-vs-v0.2.0.md

🎯 API compatibility check completed!
📂 Reports saved in project root:
   • api-compat-ack-vs-v0.2.0.md
   • api-compat-ack_generator-vs-v0.2.0.md
```

## 📋 Available Tags

To see available tags for comparison:

```bash
git tag -l --sort=-version:refname
```

## 🔍 Understanding Reports

### CLI Output Symbols
- ✅ **Green**: No breaking changes detected
- ⚠️ **Yellow**: API changes detected (review the markdown report)

### Generated Files
- `api-compat-ack-vs-{TAG}.md` - Detailed report for ack package
- `api-compat-ack_generator-vs-{TAG}.md` - Detailed report for ack_generator package

## 🛠️ Troubleshooting

### "No previous release found"
- Ensure the tag exists: `git tag -l | grep v0.2.0`
- Check the tag format (with or without 'v' prefix)

### "Command fails"
- Ensure `dart_apitool` is installed (command installs it automatically)
- Verify packages exist on pub.dev for the specified version

## 🎯 Usage Patterns

### Before Release
```bash
# Check against last stable release
melos api-check v0.2.0

# Check against beta release  
melos api-check v0.3.0-beta.1
```

### During Development
```bash
# Compare against any previous version
melos api-check v0.1.0
```

## 📚 Migration from Old Commands

The following complex commands have been replaced by the single `melos api-check` command:

- ~~`melos api:compare --TAG=v0.2.0`~~ → `melos api-check v0.2.0`
- ~~`melos api:vs-last`~~ → `melos api-check {last-tag}`
- ~~`melos api-report`~~ → Reports generated automatically
- ~~`melos api:baseline:*`~~ → No longer needed
- ~~All 19 api-related commands~~ → Single `melos api-check` command

## 🔗 Quick Links

- **[Development Guide](../../DEVELOPMENT.md)** - Complete workflows and setup
- **[dart_apitool Package](https://pub.dev/packages/dart_apitool)** - Official tool documentation
- **[Semantic Versioning](https://semver.org/)** - Version strategy guide
- **[Melos Commands](../../melos.yaml)** - All available scripts