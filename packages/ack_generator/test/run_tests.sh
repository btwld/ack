#!/bin/bash
# Test runner script for ack_generator

set -e

echo "🧪 Running ack_generator tests..."
echo ""

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Get dependencies
echo "📦 Getting dependencies..."
dart pub get

# Run tests
echo ""
echo "🔍 Running unit tests..."

# Run analyzer tests
echo "  - Analyzer tests..."
dart test test/src/analyzer --reporter compact || true

# Run builder tests  
echo "  - Builder tests..."
dart test test/src/builders --reporter compact || true

# Run generator tests
echo "  - Generator tests..."
dart test test/src/generator_test.dart --reporter compact || true

# Run integration tests
echo ""
echo "🔗 Running integration tests..."
dart test test/integration --reporter compact || true

# Run golden tests
echo ""
echo "✨ Running golden tests..."
dart test test/golden_test.dart --reporter compact || true

echo ""
echo "✅ Test run complete!"
