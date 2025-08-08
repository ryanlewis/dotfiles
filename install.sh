#!/bin/bash
# Install script for dotfiles
# Usage: ./install.sh [options]
# Options:
#   --ci              Run in CI mode (non-interactive)
#   --no-confirm      Skip confirmation prompts
#   --help            Show this help message

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Parse arguments
CI_MODE=false
NO_CONFIRM=false
QUICK_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ci)
            CI_MODE=true
            NO_CONFIRM=true
            export CI=true
            export DEBIAN_FRONTEND=noninteractive
            shift
            ;;
        --no-confirm)
            NO_CONFIRM=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --ci         Run in CI mode (non-interactive)"
            echo "  --no-confirm Skip confirmation prompts"
            echo "  --quick      Skip language runtimes, install tools only"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ "$CI_MODE" == "true" ]]; then
    echo "🤖 Running in CI mode..."
else
    echo "🚀 Setting up dotfiles with chezmoi..."
fi

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=linux;;
    Darwin*)    OS_TYPE=macos;;
    *)          echo "Unsupported OS: ${OS}"; exit 1;;
esac

echo "📍 Detected OS: ${OS_TYPE}"

# Install Fish if not present
if ! command -v fish &> /dev/null; then
    echo "🐟 Installing Fish shell..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            brew install fish
        else
            echo "❌ Homebrew not found. Please install Homebrew first."
            exit 1
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            if [[ "$CI_MODE" == "true" ]]; then
                # Set timezone to prevent interactive prompts
                sudo ln -snf /usr/share/zoneinfo/UTC /etc/localtime
                echo "UTC" | sudo tee /etc/timezone > /dev/null
                sudo apt-get update -qq && sudo apt-get install -y -qq fish
            else
                sudo apt update && sudo apt install -y fish
            fi
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y fish
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm fish
        else
            echo "❌ Unsupported package manager"
            exit 1
        fi
    fi
fi

# Create local bin directory early
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Install chezmoi first - it's critical for dotfiles
if ! command -v chezmoi &> /dev/null; then
    echo "📦 Installing chezmoi..."
    # Install to ~/.local/bin for consistency with other tools
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# Verify chezmoi is available
if ! command -v chezmoi &> /dev/null; then
    echo "❌ Failed to install chezmoi. Please check your internet connection."
    exit 1
fi

# Apply chezmoi dotfiles early to get .tool-versions file
echo "🔧 Applying dotfiles with chezmoi to setup configuration files..."

# Check for existing git config values first
if [[ -z "$CHEZMOI_USER_NAME" ]]; then
    EXISTING_NAME=$(git config --global user.name 2>/dev/null || true)
    if [[ -n "$EXISTING_NAME" ]]; then
        echo "ℹ️  Using existing git config name: $EXISTING_NAME"
        export CHEZMOI_USER_NAME="$EXISTING_NAME"
    fi
fi

if [[ -z "$CHEZMOI_USER_EMAIL" ]]; then
    EXISTING_EMAIL=$(git config --global user.email 2>/dev/null || true)
    if [[ -n "$EXISTING_EMAIL" ]]; then
        echo "ℹ️  Using existing git config email: $EXISTING_EMAIL"
        export CHEZMOI_USER_EMAIL="$EXISTING_EMAIL"
    fi
fi

# If still not set, use defaults for non-interactive
if [[ -z "$CHEZMOI_USER_NAME" ]]; then
    export CHEZMOI_USER_NAME="${USER:-User}"
fi
if [[ -z "$CHEZMOI_USER_EMAIL" ]]; then
    export CHEZMOI_USER_EMAIL="${USER:-user}@$(hostname)"
fi

# Initialize and apply chezmoi to get config files including .tool-versions
# Check if chezmoi is already initialized
if [[ -d "$HOME/.local/share/chezmoi" ]]; then
    echo "  Updating chezmoi dotfiles..."
    # Update pulls latest changes from the source repo and applies them
    chezmoi update -v
else
    # First time initialization
    echo "  Initializing chezmoi with $SCRIPT_DIR..."
    chezmoi init --apply "$SCRIPT_DIR"
fi

# Install asdf if not present
if ! command -v asdf &> /dev/null; then
    if [[ -d "$HOME/.asdf" ]]; then
        echo "📁 asdf directory exists, checking if it's valid..."
        # Try to update existing asdf installation
        if [[ -d "$HOME/.asdf/.git" ]]; then
            echo "🔄 Updating existing asdf installation..."
            # renovate: datasource=github-releases depName=asdf-vm/asdf
            (cd "$HOME/.asdf" && git fetch --tags && git checkout v0.18.0 2>/dev/null || true)
        else
            echo "⚠️  Invalid asdf directory found, removing and reinstalling..."
            rm -rf "$HOME/.asdf"
            echo "🔧 Installing asdf..."
            # renovate: datasource=github-releases depName=asdf-vm/asdf
            git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0
        fi
    else
        echo "🔧 Installing asdf..."
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.18.0
    fi
fi

# Source asdf for current session
if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    . "$HOME/.asdf/asdf.sh"
    export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH"
fi

# Verify asdf is available
if ! command -v asdf &> /dev/null; then
    echo "❌ Failed to set up asdf. Please check installation."
    exit 1
fi

# Install essential build tools
echo "📦 Installing build dependencies..."
if [[ "$OS_TYPE" == "linux" ]]; then
    if command -v apt &> /dev/null; then
        if [[ "$CI_MODE" == "true" ]]; then
            sudo apt-get update -qq && sudo apt-get install -y -qq build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl unzip llvm libncurses5-dev \
                libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git
        else
            sudo apt update && sudo apt install -y build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl unzip llvm libncurses5-dev \
                libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git
        fi
    fi
fi

# Setup asdf plugins and install runtimes (skip in quick mode)
if [[ "$QUICK_MODE" == "false" ]]; then
    echo "🔌 Setting up asdf plugins..."

    # Node.js
    if ! asdf plugin list | grep -q "^nodejs$"; then
        echo "📦 Adding nodejs plugin..."
        asdf plugin add nodejs
    fi

    # Python
    if ! asdf plugin list | grep -q "^python$"; then
        echo "📦 Adding python plugin..."
        asdf plugin add python
    fi

    # Go
    if ! asdf plugin list | grep -q "^golang$"; then
        echo "📦 Adding golang plugin..."
        asdf plugin add golang
    fi

    # Now that we have .tool-versions from chezmoi, use asdf install to read from it
    echo "🚀 Installing runtime versions from .tool-versions..."
    
    # Change to home directory where .tool-versions was created by chezmoi
    cd "$HOME"
    
    # Install all versions specified in .tool-versions
    echo "📦 Installing all tool versions specified in ~/.tool-versions..."
    asdf install || echo "⚠️  Some tool installations may have failed, continuing..."
    
    # Reshim to ensure all binaries are available
    asdf reshim
    
    # Verify runtimes are available
    echo "✅ Verifying runtimes..."
    command -v node >/dev/null && echo "  ✓ Node.js: $(node --version)"
    command -v python3 >/dev/null && echo "  ✓ Python: $(python3 --version)"
    command -v go >/dev/null && echo "  ✓ Go: $(go version)"
    
    # Change back to script directory
    cd "$SCRIPT_DIR"
fi  # End of language runtime installation

# Install Bun using official installer (always gets latest version)
if ! command -v bun &> /dev/null; then
    echo "🥟 Installing Bun (latest version)..."
    curl -fsSL https://bun.sh/install | bash
    # Add to current session PATH
    export PATH="$HOME/.bun/bin:$PATH"
fi
command -v bun >/dev/null && echo "  ✓ Bun: $(bun --version)"

# Install command-line tools
# Local bin directory already created and PATH set at beginning

echo "🛠️ Installing command-line tools..."

# Install fzf (fuzzy finder)
if ! command -v fzf &> /dev/null; then
    echo "🔍 Installing fzf..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install fzf
    elif [[ "$OS_TYPE" == "linux" ]]; then
        # Download binary release instead of using git installer
        # renovate: datasource=github-releases depName=junegunn/fzf
        FZF_VERSION="0.65.1"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            FZF_ARCH="linux_amd64"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            FZF_ARCH="linux_arm64"
        else
            echo "⚠️  FZF not available for $ARCH"
        fi
        
        if [[ -n "$FZF_ARCH" ]]; then
            wget -qO /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-${FZF_ARCH}.tar.gz"
            tar -xzf /tmp/fzf.tar.gz -C /tmp fzf
            mv /tmp/fzf "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/fzf"
        fi
    fi
fi

# Install bat (better cat)
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    echo "🦇 Installing bat..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install bat
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y bat
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y bat
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm bat
        fi
    fi
fi

# Install fd (better find)
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    echo "🔎 Installing fd..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install fd
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y fd-find
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y fd-find
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm fd
        fi
    fi
fi

# Install ripgrep (better grep)
if ! command -v rg &> /dev/null; then
    echo "🔍 Installing ripgrep..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install ripgrep
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y ripgrep
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y ripgrep
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm ripgrep
        fi
    fi
fi

# Install zoxide (smarter cd)
if ! command -v zoxide &> /dev/null; then
    echo "📂 Installing zoxide..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install zoxide
    elif [[ "$OS_TYPE" == "linux" ]]; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -s -- --bin-dir "$HOME/.local/bin"
    fi
fi

# Install eza (better ls)
if ! command -v eza &> /dev/null; then
    echo "📋 Installing eza..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install eza
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo apt update && sudo apt install -y eza
        elif command -v cargo &> /dev/null; then
            cargo install eza
        fi
    fi
fi

# Install delta (better git diff)
if ! command -v delta &> /dev/null; then
    echo "🎨 Installing delta..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install git-delta
    elif [[ "$OS_TYPE" == "linux" ]]; then
        # Download binary release directly - package managers often don't have it
        # renovate: datasource=github-releases depName=dandavison/delta
        DELTA_VERSION="0.18.2"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            DELTA_ARCH="x86_64-unknown-linux-musl"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            DELTA_ARCH="aarch64-unknown-linux-gnu"
        else
            echo "⚠️  Delta not available for $ARCH"
        fi
        
        if [[ -n "$DELTA_ARCH" ]]; then
            echo "  Downloading delta ${DELTA_VERSION} for ${DELTA_ARCH}..."
            wget -qO /tmp/delta.tar.gz "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-${DELTA_ARCH}.tar.gz"
            tar -xzf /tmp/delta.tar.gz -C /tmp
            mv /tmp/delta-${DELTA_VERSION}-${DELTA_ARCH}/delta "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/delta"
        fi
    fi
fi

# Install lazygit
if ! command -v lazygit &> /dev/null; then
    echo "🚀 Installing lazygit..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install lazygit
    elif [[ "$OS_TYPE" == "linux" ]]; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        ARCH=$(uname -m)
        if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            LAZYGIT_ARCH="Linux_arm64"
        else
            LAZYGIT_ARCH="Linux_x86_64"
        fi
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_${LAZYGIT_ARCH}.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        install /tmp/lazygit "$HOME/.local/bin"
    fi
fi

# Install btop
if ! command -v btop &> /dev/null; then
    echo "📊 Installing btop..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install btop
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y btop
        elif command -v snap &> /dev/null; then
            sudo snap install btop
        fi
    fi
fi

# Install tldr (tealdeer - fast tldr client in Rust)
if ! command -v tldr &> /dev/null; then
    echo "📚 Installing tldr..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Download tealdeer binary for macOS
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            echo "  Downloading tealdeer for macOS x86_64..."
            curl -sLo "$HOME/.local/bin/tldr" "https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-macos-x86_64"
            chmod +x "$HOME/.local/bin/tldr"
        elif [[ "$ARCH" == "arm64" ]]; then
            echo "  Downloading tealdeer for macOS ARM64..."
            curl -sLo "$HOME/.local/bin/tldr" "https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-macos-aarch64"
            chmod +x "$HOME/.local/bin/tldr"
        else
            # Fallback to brew if architecture not recognized
            brew install tealdeer
        fi
    elif [[ "$OS_TYPE" == "linux" ]]; then
        # Install tealdeer binary directly (not a tar.gz, just a binary)
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            echo "  Downloading tealdeer (tldr client)..."
            wget -qO "$HOME/.local/bin/tldr" "https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-linux-x86_64-musl"
            chmod +x "$HOME/.local/bin/tldr"
        elif [[ "$ARCH" == "aarch64" ]]; then
            echo "  Downloading tealdeer (tldr client) for ARM64..."
            wget -qO "$HOME/.local/bin/tldr" "https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-linux-aarch64-musl"
            chmod +x "$HOME/.local/bin/tldr"
        elif [[ "$ARCH" == "armv7l" ]]; then
            echo "  Downloading tealdeer (tldr client) for ARMv7..."
            wget -qO "$HOME/.local/bin/tldr" "https://github.com/dbrgn/tealdeer/releases/latest/download/tealdeer-linux-armv7-musleabihf"
            chmod +x "$HOME/.local/bin/tldr"
        else
            echo "⚠️  tldr not available for $ARCH"
        fi
    fi
fi

# Install jq
if ! command -v jq &> /dev/null; then
    echo "🔧 Installing jq..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install jq
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            if [[ "$CI_MODE" == "true" ]]; then
                sudo apt-get update -qq && sudo apt-get install -y -qq jq
            else
                sudo apt update && sudo apt install -y jq
            fi
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm jq
        fi
    fi
fi

# Install httpie
if ! command -v http &> /dev/null; then
    echo "🌐 Installing httpie..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install httpie
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            if [[ "$CI_MODE" == "true" ]]; then
                sudo apt-get update -qq && sudo apt-get install -y -qq httpie
            else
                sudo apt update && sudo apt install -y httpie
            fi
        elif command -v pip3 &> /dev/null; then
            pip3 install --user httpie
        fi
    fi
fi

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "🐙 Installing GitHub CLI..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install gh
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            type -p curl >/dev/null || sudo apt install curl -y
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update && sudo apt install gh -y
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y gh
        fi
    fi
fi

# Install duf (better df)
if ! command -v duf &> /dev/null; then
    echo "💾 Installing duf..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install duf
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            # duf is available in Ubuntu 22.04+ repositories
            if [[ "$CI_MODE" == "true" ]]; then
                sudo apt-get update -qq && sudo apt-get install -y -qq duf
            else
                sudo apt update && sudo apt install -y duf
            fi
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y duf
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm duf
        else
            # Fallback to binary download for other distros
            DUF_VERSION="0.8.1"
            ARCH=$(uname -m)
            if [[ "$ARCH" == "x86_64" ]]; then
                echo "  Downloading duf binary..."
                wget -q -O /tmp/duf.tar.gz "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_x86_64.tar.gz"
                tar -xzf /tmp/duf.tar.gz -C /tmp duf
                mv /tmp/duf "$HOME/.local/bin/"
                chmod +x "$HOME/.local/bin/duf"
            elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
                echo "  Downloading duf binary..."
                wget -q -O /tmp/duf.tar.gz "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_arm64.tar.gz"
                tar -xzf /tmp/duf.tar.gz -C /tmp duf
                mv /tmp/duf "$HOME/.local/bin/"
                chmod +x "$HOME/.local/bin/duf"
            else
                echo "⚠️  duf not available for $ARCH"
            fi
        fi
    fi
fi

# Install dust (better du)
if ! command -v dust &> /dev/null; then
    echo "📊 Installing dust..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install dust
    elif [[ "$OS_TYPE" == "linux" ]]; then
        DUST_VERSION="1.2.3"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            wget -O /tmp/dust.tar.gz "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
            tar -xzf /tmp/dust.tar.gz -C /tmp
            mv "/tmp/dust-v${DUST_VERSION}-x86_64-unknown-linux-gnu/dust" "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/dust"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            wget -O /tmp/dust.tar.gz "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
            tar -xzf /tmp/dust.tar.gz -C /tmp
            mv "/tmp/dust-v${DUST_VERSION}-aarch64-unknown-linux-gnu/dust" "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/dust"
        else
            if command -v cargo &> /dev/null; then
                cargo install du-dust
            else
                echo "⚠️  Dust not available for $ARCH and cargo not found"
            fi
        fi
    fi
fi

# Only install rust if absolutely needed (prefer binary releases)
# Rust installation will be deferred until a tool requires it

# Install broot (file browser)
if ! command -v broot &> /dev/null; then
    echo "🌳 Installing broot..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install broot
    elif [[ "$OS_TYPE" == "linux" ]]; then
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            echo "  Downloading broot binary..."
            wget -qO /tmp/broot https://dystroy.org/broot/download/x86_64-linux/broot
            chmod +x /tmp/broot
            mv /tmp/broot "$HOME/.local/bin/"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            echo "  Downloading broot for ARM64..."
            # Use a specific version that we know works
            wget -qO /tmp/broot https://dystroy.org/broot/download/aarch64-linux/broot
            chmod +x /tmp/broot
            mv /tmp/broot "$HOME/.local/bin/"
        else
            echo "⚠️  Broot binary not available for $ARCH"
        fi
    fi
fi

# Install atuin (better shell history)
if ! command -v atuin &> /dev/null; then
    echo "📜 Installing atuin..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install atuin
    elif [[ "$OS_TYPE" == "linux" ]]; then
        # Download binary release instead of using installer
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            ATUIN_ARCH="x86_64-unknown-linux-gnu"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            ATUIN_ARCH="aarch64-unknown-linux-gnu"
        else
            echo "⚠️  Atuin not available for $ARCH"
        fi
        
        if [[ -n "$ATUIN_ARCH" ]]; then
            # renovate: datasource=github-releases depName=atuinsh/atuin
            ATUIN_VERSION="v18.8.0"
            echo "  Downloading atuin ${ATUIN_VERSION} for ${ATUIN_ARCH}..."
            if wget -O /tmp/atuin.tar.gz "https://github.com/atuinsh/atuin/releases/download/${ATUIN_VERSION}/atuin-${ATUIN_ARCH}.tar.gz" 2>/dev/null; then
                echo "  Extracting atuin..."
                if tar -xzf /tmp/atuin.tar.gz -C /tmp 2>/dev/null; then
                    # The binary is in a subdirectory
                    if [[ -f "/tmp/atuin-${ATUIN_ARCH}/atuin" ]]; then
                        mv "/tmp/atuin-${ATUIN_ARCH}/atuin" "$HOME/.local/bin/"
                        chmod +x "$HOME/.local/bin/atuin"
                        echo "  ✓ Atuin installed successfully"
                    else
                        echo "  ⚠️  Failed to find atuin binary in archive"
                    fi
                else
                    echo "  ⚠️  Failed to extract atuin archive"
                fi
            else
                echo "  ⚠️  Failed to download atuin"
            fi
        fi
    fi
fi

# Install starship prompt
if ! command -v starship &> /dev/null; then
    echo "⭐ Installing starship..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install starship
    elif [[ "$OS_TYPE" == "linux" ]]; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    fi
fi

# Install direnv
if ! command -v direnv &> /dev/null; then
    echo "📁 Installing direnv..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install direnv
    elif [[ "$OS_TYPE" == "linux" ]]; then
        if command -v apt &> /dev/null; then
            if [[ "$CI_MODE" == "true" ]]; then
                sudo apt-get update -qq && sudo apt-get install -y -qq direnv
            else
                sudo apt update && sudo apt install -y direnv
            fi
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y direnv
        else
            export bin_path="$HOME/.local/bin"
            mkdir -p "$bin_path"
            curl -sfL https://direnv.net/install.sh | bash -s -- -b "$bin_path"
        fi
    fi
fi

# Install just
if ! command -v just &> /dev/null; then
    echo "🔨 Installing just..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install just
    elif [[ "$OS_TYPE" == "linux" ]]; then
        # Use pre-built binary
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            JUST_ARCH="x86_64-unknown-linux-musl"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            JUST_ARCH="aarch64-unknown-linux-musl"
        else
            echo "⚠️  Just not available for $ARCH"
            continue
        fi
        # renovate: datasource=github-releases depName=casey/just
        JUST_VERSION="1.42.4"
        wget -qO /tmp/just.tar.gz "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_ARCH}.tar.gz"
        tar -xzf /tmp/just.tar.gz -C /tmp just
        mv /tmp/just "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/just"
    fi
fi

# Install kubectl (Kubernetes CLI)
if ! command -v kubectl &> /dev/null; then
    echo "☸️  Installing kubectl..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        brew install kubectl
    elif [[ "$OS_TYPE" == "linux" ]]; then
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            KUBECTL_ARCH="amd64"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            KUBECTL_ARCH="arm64"
        else
            echo "⚠️  kubectl not available for $ARCH"
        fi
        
        if [[ -n "$KUBECTL_ARCH" ]]; then
            # Get latest stable version
            KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
            echo "  Installing kubectl ${KUBECTL_VERSION}..."
            
            # Download kubectl binary
            curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"
            
            # Make executable and move to local bin
            chmod +x kubectl
            mv kubectl "$HOME/.local/bin/"
        fi
    fi
fi

# Install kubectx and kubens for Kubernetes namespace/context switching
if command -v kubectl &> /dev/null; then
    # Install kubectx and kubens
    if ! command -v kubectx &> /dev/null || ! command -v kubens &> /dev/null; then
        echo "☸️  Installing kubectx and kubens..."
        if [[ "$OS_TYPE" == "macos" ]]; then
            brew install kubectx
        elif [[ "$OS_TYPE" == "linux" ]]; then
            # renovate: datasource=github-releases depName=ahmetb/kubectx
            KUBECTX_VERSION="0.9.5"
            ARCH=$(uname -m)
            if [[ "$ARCH" == "x86_64" ]]; then
                KUBECTX_ARCH="linux_x86_64"
            elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
                KUBECTX_ARCH="linux_arm64"
            else
                echo "⚠️  kubectx/kubens not available for $ARCH"
            fi
            
            if [[ -n "$KUBECTX_ARCH" ]]; then
                # Download and install kubectx if not present
                if ! command -v kubectx &> /dev/null; then
                    wget -qO /tmp/kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_${KUBECTX_ARCH}.tar.gz"
                    tar -xzf /tmp/kubectx.tar.gz -C /tmp kubectx
                    mv /tmp/kubectx "$HOME/.local/bin/"
                    chmod +x "$HOME/.local/bin/kubectx"
                fi
                
                # Download and install kubens if not present
                if ! command -v kubens &> /dev/null; then
                    wget -qO /tmp/kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_${KUBECTX_ARCH}.tar.gz"
                    tar -xzf /tmp/kubens.tar.gz -C /tmp kubens
                    mv /tmp/kubens "$HOME/.local/bin/"
                    chmod +x "$HOME/.local/bin/kubens"
                fi
            fi
        fi
    fi
fi

# Chezmoi already installed at the beginning of the script

# Note: Chezmoi dotfiles already applied earlier in the script

# Install Fisher plugin manager for Fish
if command -v fish &> /dev/null; then
    echo "🐟 Installing Fisher plugin manager..."
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || {
        echo "⚠️  Fisher installation may require running Fish interactively"
    }
    
    # Install fzf.fish plugin for better FZF integration
    if fish -c "type -q fisher" 2>/dev/null; then
        echo "🔍 Installing fzf.fish plugin..."
        fish -c "fisher install PatrickF1/fzf.fish" 2>/dev/null || {
            echo "⚠️  fzf.fish installation may require running Fish interactively"
        }
    fi
fi

# Set Fish as default shell if not already (skip in CI mode)
if [[ "$CI_MODE" == "false" ]] && [[ "$SHELL" != *"fish"* ]]; then
    echo "🐟 Setting Fish as default shell..."
    if grep -q "$(which fish)" /etc/shells; then
        chsh -s "$(which fish)"
    else
        echo "$(which fish)" | sudo tee -a /etc/shells
        chsh -s "$(which fish)"
    fi
    echo "🎉 Please log out and back in for the shell change to take effect."
elif [[ "$CI_MODE" == "true" ]]; then
    echo "📌 Skipping shell change in CI mode"
fi

# Export paths for current session
export PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$HOME/.bun/bin:$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"

# Setup command aliases for Ubuntu
if [[ "$OS_TYPE" == "linux" ]] && [[ -f "./setup-aliases.sh" ]]; then
    ./setup-aliases.sh
fi

echo "🎯 Done! Your dotfiles are ready to use."
echo ""
echo "📌 Important: For all tools to work properly in new shells:"
echo "   - Fish users: The config is already set up"
echo "   - Bash users: Add this to ~/.bashrc:"
echo "     . $HOME/.asdf/asdf.sh"
echo "     export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "🔧 All tools are installed to ~/.local/bin for easy management"