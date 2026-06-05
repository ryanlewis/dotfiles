#!/bin/bash
# Recommend Zsh as the default login shell - runs once after everything else
set -e

# Skip in CI mode
if [[ "${CI:-}" == "true" ]]; then
    echo "⏭️  Skipping shell change (CI mode)"
    exit 0
fi

# Skip if already using zsh
if [[ "$SHELL" == *"zsh" ]]; then
    echo "✓ Zsh is already your default shell"
    exit 0
fi

# Check if zsh is installed
if ! command -v zsh &> /dev/null; then
    echo "⚠️  Zsh not found, skipping shell change"
    exit 0
fi

ZSH_PATH=$(which zsh)

# Add zsh to valid shells if not already there
if ! grep -q "^${ZSH_PATH}$" /etc/shells; then
    echo "Adding Zsh to /etc/shells..."
    echo "${ZSH_PATH}" | sudo tee -a /etc/shells >/dev/null
fi

# Prompt user to change shell (never chsh automatically)
echo ""
echo "🦓 Zsh is installed but not set as your default shell."
echo ""
echo "To set Zsh as your default shell, run:"
echo "  chsh -s ${ZSH_PATH}"
echo ""
if command -v fish &> /dev/null; then
    echo "Fish is also installed and kept feature-for-feature in sync; to use it instead:"
    echo "  chsh -s $(which fish)"
    echo ""
fi
