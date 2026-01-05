function mise-setup --description "Install mise tools from .tool-versions"
    if not command -v mise &> /dev/null
        echo "❌ mise not installed"
        return 1
    end

    echo "📋 Current tools:"
    mise ls

    echo ""
    echo "💡 To install tools: mise install"
    echo "💡 To update tools: mise upgrade"
end

function mise-install-latest --description "Install latest versions"
    if not command -v mise &> /dev/null
        echo "❌ mise not installed"
        return 1
    end

    # Extract tools from .tool-versions and install latest
    for tool in (cat "$HOME/.tool-versions" | grep -v '^#' | grep -v '^$' | awk '{print $1}')
        echo "🔄 Installing latest $tool..."
        mise use --global "$tool@latest"
    end

    mise ls
end

function mise-update --description "Update mise and tools"
    if not command -v mise &> /dev/null
        echo "❌ mise not installed"
        return 1
    end

    echo "💡 Update mise: mise self-update"
    echo "🔄 Updating plugins..."
    mise plugins update
    echo "💡 Upgrade tools: mise upgrade"
end
