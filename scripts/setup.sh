#!/bin/bash
# Setup script for Ack - Dart/Flutter Schema Validation Library
# Compatible with both local and Claude Code remote environments

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# ANSI color codes for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
  exit 1
}

log_step() {
  echo ""
  echo -e "${BLUE}▶${NC} ${GREEN}$1${NC}"
  echo "─────────────────────────────────────────────────"
}

# Detect environment
detect_environment() {
  if [ "${CLAUDE_CODE_REMOTE:-false}" = "true" ]; then
    log_info "Environment: Claude Code Remote"
    export IS_REMOTE=true
  else
    log_info "Environment: Local"
    export IS_REMOTE=false
  fi
}

# Setup Claude Code memory symlink
setup_claude_memory() {
  log_step "Setting up Claude Code memory"

  if [ ! -f "AGENTS.md" ]; then
    log_warning "AGENTS.md not found, skipping symlink creation"
    return 0
  fi

  # Remove existing CLAUDE.local.md if it's a regular file
  if [ -f "CLAUDE.local.md" ] && [ ! -L "CLAUDE.local.md" ]; then
    log_info "Removing existing CLAUDE.local.md file"
    rm "CLAUDE.local.md"
  fi

  # Create symlink if it doesn't exist
  if [ ! -e "CLAUDE.local.md" ]; then
    log_info "Creating symlink: CLAUDE.local.md -> AGENTS.md"
    ln -s AGENTS.md CLAUDE.local.md
    log_success "Symlink created successfully"
  else
    log_info "CLAUDE.local.md already exists"
  fi

  # Verify the symlink
  if [ -L "CLAUDE.local.md" ]; then
    local target=$(readlink CLAUDE.local.md)
    log_success "CLAUDE.local.md -> $target"
  fi
}

# Setup PATH for tools
setup_path() {
  log_step "Setting up environment PATH"

  # Add common tool paths
  export PATH="$HOME/.local/bin:$PATH"
  export PATH="$HOME/.pub-cache/bin:$PATH"  # Dart global packages
  export PATH="/usr/lib/dart/bin:$PATH"      # System Dart (APT)
  export PATH="/usr/local/dart-sdk/bin:$PATH" # Manual Dart install
  export PATH="$HOME/.local/share/mise/shims:$PATH"  # Mise

  # FVM paths
  if [ -d "$HOME/fvm/default/bin" ]; then
    export PATH="$HOME/fvm/default/bin:$PATH"
  fi

  log_success "PATH configured"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verify Dart installation
verify_dart() {
  log_step "Verifying Dart installation"

  if command_exists dart; then
    local dart_version=$(dart --version 2>&1 | head -1)
    log_success "Dart SDK: $dart_version"
    return 0
  else
    log_warning "Dart SDK not found in PATH"
    log_info "Checking standard installation locations..."

    # Check standard paths
    if [ -x "/usr/lib/dart/bin/dart" ]; then
      export PATH="/usr/lib/dart/bin:$PATH"
      log_success "Found Dart at /usr/lib/dart/bin"
      return 0
    elif [ -x "/usr/local/dart-sdk/bin/dart" ]; then
      export PATH="/usr/local/dart-sdk/bin:$PATH"
      log_success "Found Dart at /usr/local/dart-sdk/bin"
      return 0
    else
      log_error "Dart SDK not found. Please run the root setup.sh first: ./setup.sh"
    fi
  fi
}

# Verify/Install Melos
setup_melos() {
  log_step "Setting up Melos"

  if command_exists melos; then
    local melos_version=$(melos --version 2>&1 | head -1)
    log_success "Melos already installed: $melos_version"
    return 0
  fi

  log_info "Installing Melos globally..."
  if dart pub global activate melos; then
    export PATH="$HOME/.pub-cache/bin:$PATH"

    if command_exists melos; then
      log_success "Melos installed successfully"
    else
      log_warning "Melos installed but not in PATH. It will be available after shell restart."
    fi
  else
    log_error "Failed to install Melos"
  fi
}

# Setup FVM (Flutter Version Manager)
setup_fvm() {
  log_step "Setting up FVM"

  # Check if .fvmrc exists
  if [ ! -f ".fvmrc" ]; then
    log_info "No .fvmrc found, skipping FVM setup"
    return 0
  fi

  # Install FVM if not present
  if ! command_exists fvm; then
    log_info "Installing FVM..."
    dart pub global activate fvm
    export PATH="$HOME/.pub-cache/bin:$PATH"
  fi

  if command_exists fvm; then
    log_info "Installing Flutter via FVM (this may take a few minutes)..."

    # Install Flutter version from .fvmrc
    if fvm install --skip-setup; then
      log_success "Flutter version installed via FVM"

      # Use the installed version
      if fvm use --force; then
        log_success "FVM Flutter version activated"

        # Add FVM Flutter to PATH
        if [ -d ".fvm/flutter_sdk/bin" ]; then
          export PATH="$(pwd)/.fvm/flutter_sdk/bin:$PATH"
        fi
      fi
    else
      log_warning "FVM setup encountered issues, continuing anyway..."
    fi
  else
    log_warning "FVM installation failed, skipping Flutter version management"
  fi
}

# Bootstrap Melos workspace
bootstrap_workspace() {
  log_step "Bootstrapping Melos workspace"

  if ! command_exists melos; then
    log_error "Melos not available. Cannot bootstrap workspace."
  fi

  log_info "Running melos bootstrap..."
  if melos bootstrap; then
    log_success "Workspace bootstrapped successfully"
  else
    log_error "Failed to bootstrap workspace"
  fi
}

# Setup Node.js tools (JSON Schema validation)
setup_nodejs_tools() {
  log_step "Setting up Node.js validation tools"

  if [ ! -d "tools" ] || [ ! -f "tools/package.json" ]; then
    log_info "No Node.js tools found, skipping"
    return 0
  fi

  if ! command_exists npm; then
    log_warning "NPM not found, skipping Node.js tools installation"
    log_info "Node.js tools are optional but recommended for JSON Schema validation"
    return 0
  fi

  log_info "Installing npm dependencies in tools/..."
  cd tools
  if npm install --silent; then
    cd ..
    log_success "Node.js validation tools installed"
  else
    cd ..
    log_warning "Failed to install Node.js tools (non-critical)"
  fi
}

# Verify setup
verify_setup() {
  log_step "Verifying setup"

  local all_ok=true

  # Check Dart
  if command_exists dart; then
    log_success "Dart SDK: $(dart --version 2>&1 | head -1)"
  else
    log_error "Dart SDK not found"
    all_ok=false
  fi

  # Check Melos
  if command_exists melos; then
    log_success "Melos: $(melos --version 2>&1 | head -1)"
  else
    log_warning "Melos not found (may need shell restart)"
  fi

  # Check FVM (optional)
  if command_exists fvm && [ -f ".fvmrc" ]; then
    log_success "FVM: $(fvm --version 2>&1 | head -1)"
  fi

  # Check Node.js (optional)
  if command_exists node; then
    log_success "Node.js: $(node --version)"
  fi

  # Check symlink
  if [ -L "CLAUDE.local.md" ]; then
    log_success "CLAUDE.local.md symlink verified"
  fi

  if [ "$all_ok" = false ]; then
    log_error "Setup verification failed"
  fi

  log_success "Setup verification complete"
}

# Display available commands
show_next_steps() {
  echo ""
  echo "════════════════════════════════════════════════"
  echo -e "  ${GREEN}✓ Ack Setup Complete!${NC}"
  echo "════════════════════════════════════════════════"
  echo ""
  echo "Available Melos commands:"
  echo "  ${BLUE}melos test${NC}               - Run all tests"
  echo "  ${BLUE}melos build${NC}              - Generate code with build_runner"
  echo "  ${BLUE}melos analyze${NC}            - Run analyzer on all packages"
  echo "  ${BLUE}melos format${NC}             - Format all code"
  echo "  ${BLUE}melos clean${NC}              - Clean build artifacts"
  echo "  ${BLUE}melos list-scripts${NC}       - Show all available scripts"
  echo ""
  echo "Testing & Validation:"
  echo "  ${BLUE}melos validate-jsonschema${NC} - Validate JSON Schema conformance"
  echo "  ${BLUE}melos test:gen:watch${NC}     - Watch mode for generator tests"
  echo ""
  echo "Package Management:"
  echo "  ${BLUE}melos deps-outdated${NC}      - Check outdated dependencies"
  echo "  ${BLUE}melos version-patch${NC}      - Bump patch version"
  echo ""
  echo "Documentation:"
  echo "  • Architecture: ${BLUE}cat AGENTS.md${NC}"
  echo "  • Publishing: ${BLUE}cat PUBLISHING.md${NC}"
  echo "  • Docs site: ${BLUE}docs/${NC}"
  echo ""
  echo "Ready to validate! 🚀"
  echo ""
}

# Main setup flow
main() {
  # Change to repository root
  cd "$(dirname "$0")/.."

  echo ""
  echo "════════════════════════════════════════════════"
  echo "  Ack - Schema Validation Library Setup"
  echo "════════════════════════════════════════════════"
  echo ""

  detect_environment
  setup_claude_memory
  setup_path
  verify_dart
  setup_melos
  setup_fvm
  bootstrap_workspace
  setup_nodejs_tools
  verify_setup
  show_next_steps
}

# Run main function
main

exit 0