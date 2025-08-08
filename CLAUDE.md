# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform dotfiles repository managed by chezmoi. It provides a consistent development environment across macOS and Linux, optimized for Fish shell with modern CLI tool replacements.

## Essential Commands

### Installation and Setup
```bash
# Full installation with all tools and language runtimes
./install.sh

# Quick installation (tools only, no language runtimes)
./install.sh --quick

# CI mode (non-interactive, no confirmations)
./install.sh --ci --no-confirm
```

### Testing
```bash
# Run complete test suite
./test.sh

# Run minimal tests (faster)
./test.sh --minimal

# Test in Docker container (Ubuntu 24.04)
./docker-test.sh

# Docker CI mode
./docker-test.sh --ci
```

### Chezmoi Workflow
```bash
# Apply changes from source
chezmoi apply

# Add new files to be managed
chezmoi add ~/.config/fish/newfile.fish

# Edit managed files
chezmoi edit ~/.config/fish/config.fish

# See what would change
chezmoi diff

# Update from repository
chezmoi update
```

## Architecture and Key Technologies

### Core Components
- **Package Manager**: chezmoi with Go templating for OS-specific configurations
- **Shell**: Fish shell with vi-mode enabled
- **Version Manager**: asdf for Node.js, Python (Miniconda), Go, and Bun
- **Terminal Multiplexer**: tmux with vi-mode and mobile device optimizations

### Template System
- Files ending in `.tmpl` use chezmoi's Go templating
- OS detection via `{{ .chezmoi.os }}` (darwin/linux)
- Platform-specific features controlled through templates
- Ubuntu-specific handling for tool names (batcat→bat, fdfind→fd)

### Directory Structure
- `private_dot_config/`: Configs that become `~/.config/`
- `dot_*`: Files that become `~/.*` (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- Templates process during `chezmoi apply` based on OS and environment

### Tool Installation Strategy
- All tools install to `~/.local/bin`
- Prefers downloading pre-built binaries over compilation
- Automatic architecture detection (x86_64, arm64)
- Fallback installation methods for different platforms

## Development Patterns

### Fish Functions
- Custom functions in `private_dot_config/private_fish/functions/`
- FZF integration functions prefixed with `f` (fcd, fgit, fgrep)
- Functions automatically loaded by Fish on startup

### Configuration Files
- Fish config: `private_dot_config/private_fish/config.fish.tmpl`
- Tmux config: `dot_tmux.conf`
- Git config: `dot_gitconfig.tmpl`
- Starship prompt: `private_dot_config/starship.toml`

### Testing Approach
- `test.sh` verifies all tools are installed and accessible
- Tests check command availability, Fish functions, and configurations
- GitHub Actions CI tests on Ubuntu 22.04/24.04 and macOS 13/14
- Docker testing provides isolated environment verification

## Important Notes

### Mobile Development
- Tmux configured for Terminus iPhone app compatibility
- Special key mapping: Ctrl+_ mapped to Shift+Tab for Claude Code planning mode

### Modern CLI Tools
This repository replaces traditional Unix tools with modern alternatives:
- `ls` → `eza`
- `cat` → `bat`
- `find` → `fd`
- `grep` → `ripgrep (rg)`
- `cd` → `zoxide (z)`
- `top` → `btop`
- `df` → `duf`
- `du` → `dust`

### Environment Variables
- `CI`: Set in CI environments for non-interactive installation
- `QUICK_INSTALL`: Skip language runtime installations
- `NO_CONFIRM`: Skip installation confirmations

### Cross-Platform Considerations
- macOS uses Homebrew for some dependencies
- Linux supports apt, dnf, and pacman package managers
- Binary downloads automatically detect CPU architecture
- Ubuntu requires special handling for renamed packages