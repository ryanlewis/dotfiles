#!/bin/bash
# Minimal bootstrap script for dotfiles installation
# Usage: curl -fsLS https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash

set -e

echo "🚀 Starting dotfiles installation..."

# Set a writable temp directory for WSL compatibility
# WSL sometimes has issues with /tmp permissions
export TMPDIR="${HOME}/.tmp"
mkdir -p "$TMPDIR"

# Check for existing git config to avoid prompts
if [[ -z "$CHEZMOI_USER_NAME" ]]; then
    CHEZMOI_USER_NAME=$(git config --global user.name 2>/dev/null || echo "${USER:-User}")
    export CHEZMOI_USER_NAME
fi

if [[ -z "$CHEZMOI_USER_EMAIL" ]]; then
    CHEZMOI_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "${USER:-user}@$(hostname)")
    export CHEZMOI_USER_EMAIL
fi

# Install chezmoi and initialize dotfiles in one command
echo "📦 Installing chezmoi and initializing dotfiles..."
TMPDIR="$TMPDIR" bash -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ryanlewis/dotfiles

echo ""
echo "✨ Dotfiles installation complete!"
echo ""
echo "💡 Development tips:"
echo "   chezmoi cd        # Go to dotfiles directory"
echo "   chezmoi diff      # Preview changes"
echo "   chezmoi apply     # Apply changes"
echo "   chezmoi update    # Pull latest from GitHub"
echo ""
echo "🐟 Restart your terminal or run 'fish' to use your new shell"