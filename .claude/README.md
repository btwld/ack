# Claude Code Configuration

This directory contains team-wide Claude Code settings for the ack project.

## Files in This Directory

### `settings.json` (Team Settings - Committed)

Team-wide configuration shared by all developers.

**Current Configuration:**
- **sessionStart hook:** Runs `scripts/setup.sh` automatically when Claude Code session starts
- **Default model:** Sonnet (can be overridden)
- **Default shell:** Bash

### Personal Overrides (Not Committed)

You can create personal overrides that won't be committed:

**`.claude/settings.local.json`** - Personal settings that override team settings

Example:
```json
{
  "model": {
    "default": "opus"
  }
}
```

**`CLAUDE.local.md`** (in root) - Personal instructions that override `CLAUDE.md`

Example:
```markdown
# My Personal Preferences

- Always run tests in verbose mode
- Use detailed logging
- Prefer functional patterns
```

## Settings Precedence

Settings are loaded in this order (highest precedence last):

1. User global settings (`~/.claude/settings.json`)
2. Project settings (`.claude/settings.json`) ← This file
3. Project local (`.claude/settings.local.json`) ← Your personal overrides
4. Command-line arguments
5. Enterprise policies

## Memory/Context Hierarchy

Claude Code loads context files in this order:

1. Enterprise (`/Library/Application Support/ClaudeCode/CLAUDE.md`)
2. User Global (`~/.claude/CLAUDE.md`)
3. Project (`./CLAUDE.md`) ← Imports AGENTS.md
4. Project Local (`./CLAUDE.local.md`) ← Your personal instructions

## How It Works

When you start a Claude Code session:

1. **sessionStart hook triggers** → Runs `scripts/setup.sh`
2. **Setup script runs** → Installs Dart SDK, Node.js, Melos, and bootstraps workspace
3. **Claude reads CLAUDE.md** → Sees `@AGENTS.md` import
4. **Import resolved** → Loads full architecture documentation
5. **Agent ready** → Has complete environment setup and project knowledge

## Modifying Team Settings

To change team settings:

1. Edit `.claude/settings.json`
2. Test locally
3. Commit changes
4. Push to repository

Everyone on the team will get the updated settings.

## Available Hooks

Claude Code supports these hooks:

- `sessionStart` - Runs when session starts (currently configured)
- `sessionEnd` - Runs when session ends
- `preToolUse` - Runs before each tool use
- `postToolUse` - Runs after each tool use
- `userPromptSubmit` - Runs when user submits a prompt

## Documentation

- **Claude Code Docs:** https://docs.claude.com/en/docs/claude-code
- **Settings Reference:** https://docs.claude.com/en/docs/claude-code/settings.md
- **Memory & Imports:** https://docs.claude.com/en/docs/claude-code/memory.md

## Project-Specific Notes

### Setup Script

The `scripts/setup.sh` script:
- Installs Dart SDK
- Installs Node.js
- Installs Melos
- Bootstraps the workspace
- Installs Node.js dependencies for JSON Schema validation tools

It's designed to be idempotent (safe to run multiple times).

### Project Context

The `AGENTS.md` file contains:
- Project architecture overview
- Package structure and dependencies
- Key patterns and conventions
- Development workflows
- Common commands
- Testing strategy
- Recent changes and current state

This gives Claude Code full context about the ack project.

## Troubleshooting

### Setup Script Fails

Run manually to debug:
```bash
./scripts/setup.sh
```

### Import Not Working

Verify syntax in `CLAUDE.md`:
```bash
cat CLAUDE.md
# Should show: > Project Context: @AGENTS.md
```

### Agent Doesn't Have Context

Ask in session: "What do you know about this project's architecture?"

If the agent doesn't have context, check that:
1. `AGENTS.md` exists and is committed
2. `CLAUDE.md` exists with correct import syntax
3. Files are not in `.gitignore`

## Questions?

See the main project documentation or open an issue on GitHub.
