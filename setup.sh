#!/bin/bash
set -e

echo "🔧 Setting up Dart ACK workspace environment..."

# Install Dart SDK with proper GPG key handling
echo "📦 Installing Dart SDK..."
sudo apt-get update
sudo apt-get install -y apt-transport-https wget gnupg

# Add Dart GPG key and repository
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list

# Update package list and install Dart
sudo apt-get update
sudo apt-get install -y dart

# Install Node.js for JSON Schema validation tools
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Set up PATH for current session and future sessions
export PATH="$PATH:/usr/lib/dart/bin"
export PATH="$PATH:$HOME/.pub-cache/bin"
echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> $HOME/.profile
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> $HOME/.profile

# Verify installations
echo "✅ Verifying installations..."
dart --version
node --version
npm --version

# Install Melos globally
echo "📦 Installing Melos..."
dart pub global activate melos

# Refresh PATH to include newly installed global packages
export PATH="$PATH:$HOME/.pub-cache/bin"

# Bootstrap the workspace (install dependencies for all packages)
echo "🔄 Bootstrapping Melos workspace..."
melos bootstrap

# Install Node.js dependencies for JSON Schema validation tools
echo "📦 Installing Node.js dependencies for validation tools..."
cd tools
npm install
cd ..

echo "✅ Setup complete!"