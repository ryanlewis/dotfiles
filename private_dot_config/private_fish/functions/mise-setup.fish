function mise-setup --description "Show mise tools and install hints"
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

function mise-install-latest --description "Install latest versions of all configured tools"
    if not command -v mise &> /dev/null
        echo "❌ mise not installed"
        return 1
    end

    for tool in (mise ls --current --json | jq -r 'keys[]')
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
