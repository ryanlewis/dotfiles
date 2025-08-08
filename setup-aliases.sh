#!/bin/bash
# Create symlinks for tools with different names on Ubuntu

set -e

echo "🔗 Setting up command aliases..."

# Create symlinks in ~/.local/bin
mkdir -p ~/.local/bin

# bat -> batcat
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    ln -sf $(which batcat) ~/.local/bin/bat
    echo "  ✓ Created alias: bat -> batcat"
fi

# fd -> fdfind
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    ln -sf $(which fdfind) ~/.local/bin/fd
    echo "  ✓ Created alias: fd -> fdfind"
fi

# Create symlinks for cargo-installed tools if they exist
if [[ -d "$HOME/.cargo/bin" ]]; then
    for tool in broot just atuin; do
        if [[ -f "$HOME/.cargo/bin/$tool" ]] && [[ ! -f "$HOME/.local/bin/$tool" ]]; then
            ln -sf "$HOME/.cargo/bin/$tool" "$HOME/.local/bin/$tool"
            echo "  ✓ Created symlink: $tool"
        fi
    done
fi

# Create symlinks for go-installed tools if they exist
if [[ -d "$HOME/go/bin" ]]; then
    for tool in duf; do
        if [[ -f "$HOME/go/bin/$tool" ]] && [[ ! -f "$HOME/.local/bin/$tool" ]]; then
            ln -sf "$HOME/go/bin/$tool" "$HOME/.local/bin/$tool"
            echo "  ✓ Created symlink: $tool"
        fi
    done
fi

echo "✅ Aliases created successfully!"