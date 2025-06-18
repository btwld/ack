#!/bin/bash

# API Baseline Management Script for Ack Library
# This script helps manage API baselines for development and testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASELINE_FILE="$PROJECT_ROOT/api-model-ack-baseline.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if dart_apitool is installed
check_dart_apitool() {
    if ! command -v dart-apitool &> /dev/null; then
        print_error "dart_apitool is not installed or not in PATH"
        print_status "Installing dart_apitool..."
        dart pub global activate dart_apitool
        print_success "dart_apitool installed successfully"
    fi
}

# Function to create a new baseline
create_baseline() {
    print_status "Creating new API baseline from current state..."
    
    cd "$PROJECT_ROOT"
    
    # Remove existing baseline if it exists
    if [ -f "$BASELINE_FILE" ]; then
        print_warning "Removing existing baseline file"
        rm "$BASELINE_FILE"
    fi
    
    # Extract current API
    dart-apitool extract \
        --input "./packages/ack" \
        --output "$BASELINE_FILE"
    
    print_success "Baseline created: $(basename "$BASELINE_FILE")"
    print_status "You can now make API changes and run 'check' to see differences"
}

# Function to check changes against baseline
check_changes() {
    if [ ! -f "$BASELINE_FILE" ]; then
        print_error "No baseline file found: $(basename "$BASELINE_FILE")"
        print_status "Run '$0 create' to create a baseline first"
        exit 1
    fi
    
    print_status "Checking API changes against baseline..."
    
    cd "$PROJECT_ROOT"
    
    # Run the diff
    if dart-apitool diff \
        --old "$BASELINE_FILE" \
        --new "./packages/ack" \
        --report-format cli; then
        print_success "API check completed successfully"
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            print_warning "API changes detected - review the output above"
        else
            print_error "API check failed with exit code $exit_code"
            exit $exit_code
        fi
    fi
}

# Function to generate detailed report
generate_report() {
    if [ ! -f "$BASELINE_FILE" ]; then
        print_error "No baseline file found: $(basename "$BASELINE_FILE")"
        print_status "Run '$0 create' to create a baseline first"
        exit 1
    fi
    
    local report_file="$PROJECT_ROOT/api-changes-report.md"
    
    print_status "Generating detailed API changes report..."
    
    cd "$PROJECT_ROOT"
    
    dart-apitool diff \
        --old "$BASELINE_FILE" \
        --new "./packages/ack" \
        --report-format markdown \
        --report-file-path "$report_file"
    
    print_success "Report generated: $(basename "$report_file")"
}

# Function to check against last release (development mode)
check_release_dev() {
    cd "$PROJECT_ROOT"

    # Get the last released version tag
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -z "$LAST_TAG" ]; then
        print_warning "No previous release tag found"
        print_status "Creating baseline for first release..."
        dart-apitool extract \
            --input "./packages/ack" \
            --output "api-baseline-first-release.json"
        print_success "Baseline created for first release"
        return 0
    fi

    print_status "Checking API changes against last release: $LAST_TAG (development mode)"

    # Remove 'v' prefix if present
    VERSION="${LAST_TAG#v}"

    # Use lenient mode for pre-1.0 development
    if dart-apitool diff \
        --old "pub://ack/$VERSION" \
        --new "./packages/ack" \
        --report-format cli \
        --ignore-prerelease \
        --version-check-mode onlyBreakingChanges \
        --ignore-requiredness; then
        print_success "API check against release $LAST_TAG completed successfully"
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            print_warning "API changes detected compared to release $LAST_TAG"
            print_status "This is normal for pre-1.0 development. Review changes and proceed if intentional."
            return 0  # Don't fail in development mode
        else
            print_error "API check failed with exit code $exit_code"
            exit $exit_code
        fi
    fi
}

# Function to check against last release (strict mode)
check_release_strict() {
    cd "$PROJECT_ROOT"

    # Get the last released version tag
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -z "$LAST_TAG" ]; then
        print_error "No previous release tag found"
        print_status "Cannot perform strict check without previous release"
        exit 1
    fi

    print_status "Checking API changes against last release: $LAST_TAG (strict mode)"

    # Remove 'v' prefix if present
    VERSION="${LAST_TAG#v}"

    if dart-apitool diff \
        --old "pub://ack/$VERSION" \
        --new "./packages/ack" \
        --report-format cli \
        --ignore-prerelease \
        --version-check-mode fully; then
        print_success "✅ API check passed - ready for release!"
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            print_error "❌ Breaking changes detected - version bump required"
            print_status "Review the changes above and ensure proper version increment"
            exit 1
        else
            print_error "API check failed with exit code $exit_code"
            exit $exit_code
        fi
    fi
}

# Function to show help
show_help() {
    echo "API Baseline Management Script for Ack Library"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  create           Create a new API baseline from current state"
    echo "  check            Check current API against baseline"
    echo "  report           Generate detailed markdown report of changes"
    echo "  release-dev      Check against last release (development mode - warnings only)"
    echo "  release          Check against last release (strict mode - for final validation)"
    echo "  pre-release      Comprehensive pre-release validation"
    echo "  compare-tag      Compare against a specific git tag"
    echo "  list-tags        Show available git tags for comparison"
    echo "  help             Show this help message"
    echo ""
    echo "Tag Comparison:"
    echo "  $0 compare-tag <tag> [dev|strict]"
    echo "  Examples:"
    echo "    $0 compare-tag v0.2.0              # Compare against v0.2.0 (dev mode)"
    echo "    $0 compare-tag v0.3.0-beta.1 strict # Compare against beta (strict mode)"
    echo "    $0 list-tags                       # Show available tags"
    echo ""
    echo "Development Workflow (Pre-1.0):"
    echo "  1. Run '$0 create' to establish baseline"
    echo "  2. Make your API changes"
    echo "  3. Run '$0 check' to see what changed"
    echo "  4. Run '$0 compare-tag v0.2.0' to check against specific version"
    echo "  5. Run '$0 release-dev' for lenient release check"
    echo "  6. Run '$0 report' for detailed analysis"
    echo ""
    echo "Release Workflow:"
    echo "  1. Run '$0 compare-tag v0.3.0-beta.1 strict' to validate against last version"
    echo "  2. Run '$0 pre-release' for comprehensive validation"
    echo "  3. Run '$0 release' for final strict check"
    echo "  4. Tag and publish if checks pass"
    echo ""
    echo "Modes:"
    echo "  - Development: Lenient checking, warnings for breaking changes"
    echo "  - Strict: Fails on any breaking changes (for releases)"
    echo "  - Pre-release: Comprehensive validation with detailed reports"
}

# Function to check against a specific tag/version
check_against_tag() {
    local target_tag="$1"
    local mode="${2:-dev}"  # dev or strict

    if [ -z "$target_tag" ]; then
        print_error "No tag specified"
        print_status "Usage: $0 compare-tag <tag> [dev|strict]"
        exit 1
    fi

    cd "$PROJECT_ROOT"

    # Check if tag exists
    if ! git tag -l | grep -q "^${target_tag}$"; then
        print_error "Tag '$target_tag' not found"
        print_status "Available tags:"
        git tag -l | head -10
        exit 1
    fi

    print_status "🔍 Comparing current API against tag: $target_tag"

    # Remove 'v' prefix if present for pub.dev lookup
    VERSION="${target_tag#v}"

    local report_file="$PROJECT_ROOT/api-diff-vs-${target_tag}.md"

    # Choose mode
    local version_check_mode="onlyBreakingChanges"
    local ignore_req=""
    if [ "$mode" = "strict" ]; then
        version_check_mode="fully"
    else
        ignore_req="--ignore-requiredness"
    fi

    print_status "Mode: $mode (version-check-mode: $version_check_mode)"

    if dart-apitool diff \
        --old "pub://ack/$VERSION" \
        --new "./packages/ack" \
        --report-format markdown \
        --report-file-path "$report_file" \
        --ignore-prerelease \
        --version-check-mode "$version_check_mode" \
        $ignore_req; then
        print_success "✅ API comparison completed successfully"
        print_status "📋 Report generated: $(basename "$report_file")"
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            if [ "$mode" = "strict" ]; then
                print_error "❌ Breaking changes detected compared to $target_tag"
                print_status "📋 Review report: $(basename "$report_file")"
                exit 1
            else
                print_warning "⚠️  API changes detected compared to $target_tag"
                print_status "📋 Review report: $(basename "$report_file")"
                print_status "This is normal for development. Use 'strict' mode for release validation."
                return 0
            fi
        else
            print_error "API comparison failed with exit code $exit_code"
            exit $exit_code
        fi
    fi
}

# Function to list available tags
list_tags() {
    cd "$PROJECT_ROOT"

    print_status "📋 Available git tags for comparison:"

    if ! git tag -l | head -1 > /dev/null; then
        print_warning "No git tags found"
        print_status "Create a tag first: git tag v0.3.0-beta.1"
        return 0
    fi

    echo ""
    git tag -l --sort=-version:refname | head -20 | while read tag; do
        # Get tag date
        tag_date=$(git log -1 --format=%ai "$tag" 2>/dev/null | cut -d' ' -f1)
        echo "  📌 $tag ($tag_date)"
    done

    echo ""
    print_status "Usage examples:"
    echo "  ./tools/api-baseline.sh compare-tag v0.2.0"
    echo "  ./tools/api-baseline.sh compare-tag v0.3.0-beta.1 strict"
}

# Function for pre-release validation
pre_release_check() {
    print_status "🚀 Running comprehensive pre-release validation..."

    cd "$PROJECT_ROOT"

    # Get the last released version tag
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -z "$LAST_TAG" ]; then
        print_success "🎉 First release detected - no API compatibility concerns"
        print_status "Creating release baseline..."
        dart-apitool extract \
            --input "./packages/ack" \
            --output "api-baseline-release.json"
        print_success "Release baseline created"
        return 0
    fi

    print_status "Validating API changes against release $LAST_TAG"

    # Remove 'v' prefix if present
    VERSION="${LAST_TAG#v}"

    local report_file="$PROJECT_ROOT/pre-release-validation-report.md"

    if dart-apitool diff \
        --old "pub://ack/$VERSION" \
        --new "./packages/ack" \
        --report-format markdown \
        --report-file-path "$report_file" \
        --ignore-prerelease \
        --version-check-mode fully; then
        print_success "✅ Pre-release validation passed!"
        print_status "📋 Detailed report: $(basename "$report_file")"
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            print_warning "⚠️  API changes detected - review required"
            print_status "📋 Detailed report: $(basename "$report_file")"
            print_status "Review the changes and ensure proper version increment"
            return 1
        else
            print_error "Pre-release validation failed with exit code $exit_code"
            exit $exit_code
        fi
    fi
}

# Main script logic
main() {
    # Ensure we're in the right directory
    if [ ! -f "$PROJECT_ROOT/melos.yaml" ]; then
        print_error "This script must be run from the Ack project root or tools directory"
        exit 1
    fi
    
    # Check if dart_apitool is available
    check_dart_apitool
    
    # Parse command
    case "${1:-help}" in
        "create")
            create_baseline
            ;;
        "check")
            check_changes
            ;;
        "report")
            generate_report
            ;;
        "release-dev")
            check_release_dev
            ;;
        "release")
            check_release_strict
            ;;
        "pre-release")
            pre_release_check
            ;;
        "compare-tag")
            check_against_tag "$2" "$3"
            ;;
        "list-tags")
            list_tags
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
