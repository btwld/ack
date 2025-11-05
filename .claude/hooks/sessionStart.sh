#!/bin/bash
# Claude Code Web - Session Start Hook
# This script runs when a Claude Code session starts in the web environment

set -e

# Only run in Claude Code remote (web) environment
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

echo "🔧 Setting up Ack workspace for Claude Code..."

# Navigate to repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Check if Dart is available
if ! command -v dart >/dev/null 2>&1; then
  echo "⚠️  Dart SDK not found. Running full setup..."

  # Check if setup.sh exists and run it
  if [ -f "$REPO_ROOT/setup.sh" ]; then
    echo "📦 Running setup.sh to install dependencies..."
    bash "$REPO_ROOT/setup.sh"

    # Reload PATH after setup
    export PATH="$PATH:/usr/lib/dart/bin:/usr/local/dart-sdk/bin:$HOME/.pub-cache/bin"

    # Persist PATH updates for this session
    if [ -n "$CLAUDE_ENV_FILE" ]; then
      echo "export PATH=\"\$PATH:/usr/lib/dart/bin:/usr/local/dart-sdk/bin:\$HOME/.pub-cache/bin\"" >> "$CLAUDE_ENV_FILE"
    fi
  else
    echo "❌ Error: Dart SDK not found and setup.sh is missing"
    echo "Please ensure Dart SDK is installed or add setup.sh to the repository"
    exit 1
  fi

  # Verify Dart is now available
  if ! command -v dart >/dev/null 2>&1; then
    echo "❌ Error: Failed to install Dart SDK"
    echo "Please check the setup.sh script or install Dart manually"
    exit 1
  fi
fi

echo "✓ Dart SDK: $(dart --version 2>&1 | head -1)"

# Ensure PATH includes pub-cache for global packages
export PATH="$PATH:$HOME/.pub-cache/bin"
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "export PATH=\"\$PATH:\$HOME/.pub-cache/bin\"" >> "$CLAUDE_ENV_FILE"
fi

# Check if Melos is already installed
if command -v melos >/dev/null 2>&1; then
  echo "✓ Melos already installed: $(melos --version 2>&1 | head -1)"
else
  echo "📦 Installing Melos globally..."
  dart pub global activate melos

  if command -v melos >/dev/null 2>&1; then
    echo "✓ Melos installed successfully"
  else
    echo "⚠️  Melos installed but not immediately in PATH"
    echo "   It will be available after PATH is reloaded"
  fi
fi

# Bootstrap the workspace (install dependencies for all packages)
echo "📦 Bootstrapping Melos workspace..."

if command -v melos >/dev/null 2>&1; then
  if melos bootstrap; then
    echo "✓ Workspace bootstrapped successfully"
  else
    echo "❌ Failed to bootstrap workspace"
    exit 1
  fi
else
  # Try using dart pub global run as fallback
  echo "⚠️  Using 'dart pub global run melos' as fallback..."
  if dart pub global run melos bootstrap; then
    echo "✓ Workspace bootstrapped successfully"
  else
    echo "❌ Failed to bootstrap workspace"
    exit 1
  fi
fi

# Set up environment variables for the session
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "📝 Setting environment variables..."
  echo "export MELOS_ROOT=$REPO_ROOT" >> "$CLAUDE_ENV_FILE"
  echo "✓ Environment variables set"
fi

# Summary
echo ""
echo "========================================="
echo "✅ Ack workspace ready for Claude Code!"
echo "========================================="
echo ""
echo "Project: Ack - Schema Validation Library"
echo "Location: $REPO_ROOT"
echo ""
echo "Available commands:"
echo "  melos test          - Run all tests"
echo "  melos analyze       - Analyze code"
echo "  melos format        - Format code"
echo "  melos build         - Run code generation"
echo "  melos list-scripts  - See all commands"
echo ""
echo "📖 Read CLAUDE.md for detailed project information"
echo ""
