#!/bin/bash
# Install Bun JavaScript runtime - runs once
set -e

# Skip if bun is already installed
if command -v bun &> /dev/null; then
    echo "✓ Bun already installed: $(bun --version)"
    exit 0
fi

echo "🥟 Installing Bun..."

# Use official Bun installer
curl -fsSL https://bun.sh/install | bash

# Add to current session PATH
export PATH="$HOME/.bun/bin:$PATH"

# Verify installation
if command -v bun &> /dev/null; then
    echo "✓ Bun installed successfully: $(bun --version)"
else
    echo "⚠️  Bun installation may have failed"
fi