#!/bin/bash
set -e

echo "🔧 Setting up Dart ACK workspace environment..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to add PATH to shell profile
add_to_path() {
    local path_addition="$1"
    local profile_file="$HOME/.bashrc"

    if [[ -f "$HOME/.zshrc" ]]; then
        profile_file="$HOME/.zshrc"
    fi

    if ! grep -q "$path_addition" "$profile_file" 2>/dev/null; then
        echo "export PATH=\"\$PATH:$path_addition\"" >> "$profile_file"
        echo -e "${GREEN}✓${NC} Added $path_addition to PATH in $profile_file"
    fi
}

# Check and install Dart SDK
install_dart() {
    if command_exists dart; then
        echo -e "${GREEN}✓${NC} Dart SDK already installed: $(dart --version 2>&1 | head -1)"
        return 0
    fi

    echo "📦 Installing Dart SDK..."

    # Method 1: Try APT package manager (recommended for Debian/Ubuntu)
    if command_exists apt-get; then
        echo "  → Attempting installation via APT package manager..."

        # Check if we can reach the internet
        if wget -q --spider --timeout=5 https://dl-ssl.google.com 2>/dev/null; then
            sudo apt-get update || true
            sudo apt-get install -y apt-transport-https wget gnupg || true

            # Add Dart GPG key and repository
            wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg 2>/dev/null || true
            echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list

            # Update package list and install Dart
            sudo apt-get update || true
            if sudo apt-get install -y dart; then
                export PATH="$PATH:/usr/lib/dart/bin"
                add_to_path "/usr/lib/dart/bin"
                echo -e "${GREEN}✓${NC} Dart SDK installed via APT"
                return 0
            fi
        else
            echo -e "${YELLOW}⚠${NC} No internet connection for APT installation"
        fi
    fi

    # Method 2: Download and extract Dart SDK manually
    echo "  → Attempting direct download and installation..."

    local dart_install_dir="/usr/local/dart-sdk"
    local temp_dir="/tmp/dart-install-$$"

    mkdir -p "$temp_dir"
    cd "$temp_dir"

    if wget --timeout=30 https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip -O dart-sdk.zip 2>/dev/null; then
        unzip -q dart-sdk.zip
        sudo rm -rf "$dart_install_dir"
        sudo mv dart-sdk "$dart_install_dir"

        export PATH="$PATH:$dart_install_dir/bin"
        add_to_path "$dart_install_dir/bin"

        cd - > /dev/null
        rm -rf "$temp_dir"

        echo -e "${GREEN}✓${NC} Dart SDK installed to $dart_install_dir"
        return 0
    else
        echo -e "${RED}✗${NC} Failed to download Dart SDK"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Check and install Node.js
install_nodejs() {
    if command_exists node; then
        echo -e "${GREEN}✓${NC} Node.js already installed: $(node --version)"
        return 0
    fi

    echo "📦 Installing Node.js..."

    if command_exists apt-get && wget -q --spider --timeout=5 https://deb.nodesource.com 2>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        echo -e "${GREEN}✓${NC} Node.js installed"
    else
        echo -e "${YELLOW}⚠${NC} Could not install Node.js automatically"
        echo "  Please install Node.js manually from https://nodejs.org/"
    fi
}

# Main installation flow
echo ""
echo "=== Installing Dependencies ==="
echo ""

# Install Dart SDK
if ! install_dart; then
    echo -e "${RED}✗${NC} Failed to install Dart SDK"
    echo "  Please install manually: https://dart.dev/get-dart"
    exit 1
fi

# Install Node.js (optional, for validation tools)
install_nodejs

# Verify Dart installation
echo ""
echo "=== Verifying Installations ==="
echo ""

if command_exists dart; then
    dart --version
else
    echo -e "${RED}✗${NC} Dart not found in PATH"
    echo "  Please restart your shell or run: source ~/.bashrc"
    exit 1
fi

if command_exists node; then
    echo "Node: $(node --version)"
    echo "NPM: $(npm --version)"
fi

# Install Melos globally
echo ""
echo "=== Installing Melos ==="
echo ""

if command_exists melos; then
    echo -e "${GREEN}✓${NC} Melos already installed: $(melos --version 2>&1 | head -1)"
else
    echo "📦 Installing Melos globally..."
    dart pub global activate melos

    # Add pub-cache to PATH
    export PATH="$PATH:$HOME/.pub-cache/bin"
    add_to_path "$HOME/.pub-cache/bin"

    if command_exists melos; then
        echo -e "${GREEN}✓${NC} Melos installed successfully"
    else
        echo -e "${YELLOW}⚠${NC} Melos installed but not in PATH"
        echo "  Please restart your shell or run: source ~/.bashrc"
    fi
fi

# Bootstrap the workspace
echo ""
echo "=== Bootstrapping Melos Workspace ==="
echo ""

cd "$(dirname "$0")"

if command_exists melos; then
    melos bootstrap
    echo -e "${GREEN}✓${NC} Workspace bootstrapped"
else
    echo -e "${YELLOW}⚠${NC} Melos not available, skipping bootstrap"
    echo "  Please restart your shell and run: melos bootstrap"
fi

# Install Node.js dependencies for validation tools
if [ -d "tools" ] && [ -f "tools/package.json" ]; then
    echo ""
    echo "=== Installing Validation Tools ==="
    echo ""

    if command_exists npm; then
        cd tools
        npm install
        cd ..
        echo -e "${GREEN}✓${NC} Validation tools installed"
    else
        echo -e "${YELLOW}⚠${NC} NPM not available, skipping validation tools"
    fi
fi

# Final summary
echo ""
echo "========================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Installed components:"
if command_exists dart; then
    echo "  ✓ Dart SDK: $(dart --version 2>&1 | head -1)"
fi
if command_exists node; then
    echo "  ✓ Node.js: $(node --version)"
fi
if command_exists melos; then
    echo "  ✓ Melos: $(melos --version 2>&1 | head -1)"
fi
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Verify installation: dart --version && melos --version"
echo "  3. Run tests: melos test"
echo "  4. See all available commands: melos list-scripts"
echo ""
