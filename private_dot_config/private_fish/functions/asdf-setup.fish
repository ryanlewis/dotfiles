function asdf-setup --description "Install common asdf plugins and their latest versions"
    echo "🔧 Setting up asdf plugins..."
    
    # Check if asdf is installed
    if not command -v asdf &> /dev/null
        echo "❌ asdf is not installed. Please install asdf first."
        return 1
    end
    
    # Define plugins to install
    set -l plugins nodejs python golang bun
    set -l plugin_urls \
        "" \
        "" \
        "" \
        "https://github.com/cometkim/asdf-bun.git"
    
    # Install plugins
    for i in (seq (count $plugins))
        set -l plugin $plugins[$i]
        set -l url $plugin_urls[$i]
        
        if not asdf plugin list | grep -q "^$plugin\$"
            echo "📦 Installing $plugin plugin..."
            if test -n "$url"
                asdf plugin add $plugin $url
            else
                asdf plugin add $plugin
            end
        else
            echo "✅ $plugin plugin already installed"
        end
    end
    
    # Special setup for nodejs
    if asdf plugin list | grep -q "^nodejs\$"
        echo "🔑 Importing Node.js release team OpenPGP keys..."
        bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
    end
    
    echo ""
    echo "📋 Installed plugins:"
    asdf plugin list
    
    echo ""
    echo "💡 To install the versions specified in .tool-versions, run:"
    echo "   asdf install"
    echo ""
    echo "💡 To install latest versions of all tools, run:"
    echo "   asdf-install-latest"
end

function asdf-install-latest --description "Install latest stable versions of all asdf plugins"
    for plugin in (asdf plugin list)
        echo "🔄 Installing latest $plugin..."
        asdf install $plugin latest
        asdf global $plugin latest
    end
    
    echo ""
    echo "✅ All plugins updated to latest versions:"
    asdf current
end

function asdf-update --description "Update all asdf plugins"
    echo "📝 Note: asdf v0.16+ no longer has an 'update' command"
    echo "   To update asdf itself:"
    echo "   - macOS: brew upgrade asdf"
    echo "   - Linux: Download new binary from GitHub releases"
    
    echo ""
    echo "🔄 Updating all plugins..."
    asdf plugin update --all
    
    echo "✅ All plugins updated!"
end