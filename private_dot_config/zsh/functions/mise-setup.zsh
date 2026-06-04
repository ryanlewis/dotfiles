# Show mise tools and install hints
mise-setup() {
    if ! command -v mise >/dev/null; then
        echo "❌ mise not installed"
        return 1
    fi

    echo "📋 Current tools:"
    mise ls

    echo ""
    echo "💡 To install tools: mise install"
    echo "💡 To update tools: mise upgrade"
}

# Install latest versions of all configured tools
mise-install-latest() {
    if ! command -v mise >/dev/null; then
        echo "❌ mise not installed"
        return 1
    fi

    local tool
    for tool in $(mise ls --current --json | jq -r 'keys[]'); do
        echo "🔄 Installing latest $tool..."
        mise use --global "$tool@latest"
    done

    mise ls
}

# Update mise and tools
mise-update() {
    if ! command -v mise >/dev/null; then
        echo "❌ mise not installed"
        return 1
    fi

    echo "💡 Update mise: mise self-update"
    echo "🔄 Updating plugins..."
    mise plugins update
    echo "💡 Upgrade tools: mise upgrade"
}
