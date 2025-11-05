# Ack - Claude Code Context

> Project Context: @AGENTS.md

This file imports AGENTS.md to provide full project context to Claude Code.

## Team Guidelines

- Follow conventional commits (feat:, fix:, chore:, docs:, refactor:, test:)
- Run tests before committing (`melos test`)
- Use Melos commands for all operations
- Ensure code generation is up-to-date (`melos build`)
- No lint errors allowed (`melos analyze`)

## Quality Gates

- All tests must pass
- Code generation must be current
- No static analysis errors
- Format code before committing (`melos format`)
