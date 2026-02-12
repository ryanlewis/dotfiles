#!/bin/bash
# Add custom Claude Code plugin marketplaces
# Uses run_onchange_ so it retries on next apply if auth isn't set up yet

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

# Check if marketplace is already added
if claude plugin marketplace list 2>/dev/null | grep -q "ryanlewis-plugins"; then
    echo "ryanlewis-plugins marketplace already configured"
    exit 0
fi

echo "Adding ryanlewis-plugins marketplace..."
claude plugin marketplace add github.com/ryanlewis/claude-plugins
echo "Claude Code marketplace setup complete"
