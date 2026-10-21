#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

if [[ -x .fvm/flutter_sdk/bin/flutter ]]; then
  export PATH="$repo_root/.fvm/flutter_sdk/bin:$PATH"
elif ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required but was not found." >&2
  echo "Install Flutter or run 'fvm install' when using FVM, then retry." >&2
  exit 1
else
  flutter_bin="$(dirname "$(command -v flutter)")"
  export PATH="$flutter_bin:$PATH"
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "Dart was not found next to the selected Flutter SDK." >&2
  exit 1
fi

flutter --version
dart --version

echo "Resolving workspace dependencies..."
dart pub get
dart run melos bootstrap

if [[ -f tools/npm-shrinkwrap.json ]]; then
  if command -v npm >/dev/null 2>&1; then
    echo "Installing JSON Schema validation tools..."
    npm ci --prefix tools
  else
    echo "Node.js/npm not found; skipping optional JSON Schema tooling." >&2
  fi
fi

echo "Setup complete. Run 'dart run melos run --list' to see workspace scripts."
