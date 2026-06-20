#!/bin/bash
# Set up Zsh as the login shell - runs once after everything else.
# Normally only *recommends* the switch (never chsh automatically). The one
# exception is Fish: it has been retired from these dotfiles, so a machine
# still defaulting to fish is auto-migrated to zsh.
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

# Fish has been retired from these dotfiles. If it's still the login shell,
# migrate to zsh automatically (chsh may prompt for a password).
if [[ "$SHELL" == *"fish" ]]; then
    echo ""
    echo "🐟→🦓 Fish is retired from these dotfiles; switching your login shell to Zsh..."
    if chsh -s "${ZSH_PATH}"; then
        echo "✓ Login shell changed to Zsh. Open a new terminal (or log out/in) to use it."
    else
        echo "⚠️  Could not change shell automatically. Run it yourself:"
        echo "  chsh -s ${ZSH_PATH}"
    fi
    echo ""
    exit 0
fi

# Any other non-zsh shell: recommend, never chsh automatically.
echo ""
echo "🦓 Zsh is installed but not set as your default shell."
echo ""
echo "To set Zsh as your default shell, run:"
echo "  chsh -s ${ZSH_PATH}"
echo ""
