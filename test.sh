#!/bin/bash
# Test script to verify all tools are installed correctly

# Don't exit on first error - we want to see all test results
# set -e

# Ensure PATH includes common installation directories
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Source asdf if available
if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    . "$HOME/.asdf/asdf.sh"
elif [[ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]]; then
    . "/opt/homebrew/opt/asdf/libexec/asdf.sh"
elif [[ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]]; then
    . "/usr/local/opt/asdf/libexec/asdf.sh"
fi

# Parse arguments
MINIMAL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)
            MINIMAL_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Check if running in CI
if [[ "${CI:-false}" == "true" ]]; then
    echo "🤖 Running tests in CI mode..."
else
    echo "🧪 Testing dotfiles installation..."
fi
echo "================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counters
FAILED_TESTS=0
TOTAL_TESTS=0

# Function to check if command exists
check_command() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to check Fish function
check_fish_function() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if fish -c "functions -q $1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Fish function '$1' exists"
        return 0
    else
        echo -e "${RED}✗${NC} Fish function '$1' NOT found"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo ""
echo "📦 Checking core tools..."
check_command fish
check_command chezmoi
check_command asdf

echo ""
echo "🔍 Checking modern CLI tools..."
check_command fzf
# Check for bat (batcat on Ubuntu)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if command -v batcat &> /dev/null || command -v bat &> /dev/null; then
    if command -v batcat &> /dev/null; then
        echo -e "${GREEN}✓${NC} batcat is installed (Ubuntu name for bat)"
    else
        echo -e "${GREEN}✓${NC} bat is installed"
    fi
else
    echo -e "${RED}✗${NC} bat/batcat is NOT installed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Check for fd (fdfind on Ubuntu)
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if command -v fdfind &> /dev/null || command -v fd &> /dev/null; then
    if command -v fdfind &> /dev/null; then
        echo -e "${GREEN}✓${NC} fdfind is installed (Ubuntu name for fd)"
    else
        echo -e "${GREEN}✓${NC} fd is installed"
    fi
else
    echo -e "${RED}✗${NC} fd/fdfind is NOT installed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
check_command rg
check_command zoxide
check_command eza
check_command delta
check_command lazygit
check_command btop
check_command tldr
check_command jq
check_command http
check_command gh
check_command duf
check_command dust
check_command broot
check_command atuin
check_command starship
check_command direnv
check_command just
check_command gum

echo ""
echo "☸️  Checking Kubernetes tools..."
check_command kubectl
check_command kubectx
check_command kubens

echo ""
echo "🐟 Checking Fish functions..."
check_fish_function mkcd
check_fish_function backup
check_fish_function extract
check_fish_function update
check_fish_function ports
check_fish_function myip
check_fish_function fcd
check_fish_function fopen
check_fish_function fkill
check_fish_function fgrep
check_fish_function fgit
check_fish_function asdf-setup
check_fish_function asdf-install-latest
check_fish_function asdf-update
check_fish_function ta
check_fish_function fish_greeting
check_fish_function dotfiles
check_fish_function yank

if [[ "$MINIMAL_MODE" == "false" ]]; then
    echo ""
    echo "🔧 Checking asdf plugins..."
    if command -v asdf &> /dev/null; then
        asdf plugin list
    else
        echo -e "${RED}✗${NC} asdf not available"
    fi
fi

echo ""
echo "⚙️  Checking configurations..."
if [ -f "$HOME/.config/fish/config.fish" ]; then
    echo -e "${GREEN}✓${NC} Fish config exists"
else
    echo -e "${RED}✗${NC} Fish config NOT found"
fi

if [ -f "$HOME/.config/starship.toml" ]; then
    echo -e "${GREEN}✓${NC} Starship config exists"
else
    echo -e "${RED}✗${NC} Starship config NOT found"
fi

if [ -f "$HOME/.gitconfig" ]; then
    echo -e "${GREEN}✓${NC} Git config exists"
    if grep -q "delta" "$HOME/.gitconfig" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Git configured to use delta"
    fi
else
    echo -e "${RED}✗${NC} Git config NOT found"
fi

echo ""
echo "🎯 Testing complete!"
echo "Total tests: $TOTAL_TESTS"
echo "Passed: $((TOTAL_TESTS - FAILED_TESTS))"
echo "Failed: $FAILED_TESTS"

# Exit with error if any test failed
if [[ "${FAILED_TESTS:-0}" -gt 0 ]]; then
    echo ""
    echo "❌ Tests failed!"
    exit 1
else
    echo ""
    echo "✅ All tests passed!"
    exit 0
fi