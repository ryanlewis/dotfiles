#!/bin/bash
# Add custom Claude Code plugin marketplaces
set -e

# Skip in CI or quick install mode
if [[ "${CI:-}" == "true" ]] || [[ "${QUICK_INSTALL:-}" == "true" ]]; then
    echo "Skipping Claude Code marketplace setup (CI/quick install mode)"
    exit 0
fi

# Check if claude is available
if ! command -v claude &> /dev/null; then
    echo "Claude Code not found, skipping marketplace setup"
    exit 0
fi

# Add custom marketplace (idempotent - will fail gracefully if already added)
echo "Adding ryanlewis-plugins marketplace..."
claude plugin marketplace add github.com/ryanlewis/claude-plugins || {
    echo "Marketplace may already be added, continuing..."
}

echo "Claude Code marketplace setup complete"
