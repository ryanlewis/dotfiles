# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a cross-platform dotfiles repository managed by chezmoi. It provides a consistent development environment across macOS and Linux, optimized for Fish shell with modern CLI tool replacements.

## Essential Commands

### Installation
```bash
# One-liner installation (recommended)
curl -fsLS https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash

# With environment variables
QUICK_INSTALL=true curl -fsLS https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash

# Or using chezmoi directly
chezmoi init --apply ryanlewis/dotfiles
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

### Development Workflow

After installation, your dotfiles live in chezmoi's source directory at `~/.local/share/chezmoi`.

#### Quick Commands (using Fish function)
```bash
dotfiles edit      # Go to chezmoi source for editing
dotfiles diff      # Preview changes before applying
dotfiles apply     # Apply changes locally
dotfiles push      # Commit and push all changes
dotfiles pull      # Pull latest from GitHub and apply
dotfiles status    # Check git status
```

#### Standard Chezmoi Workflow
```bash
# Make changes
chezmoi cd                      # Go to source directory
# Edit files
chezmoi diff                    # Preview changes
chezmoi apply                   # Apply locally

# Version control
chezmoi git add -A
chezmoi git commit -m "Update"
chezmoi git push

# Update from GitHub
chezmoi update                  # Pull and apply latest

# Add new files
chezmoi add ~/.config/fish/newfile.fish
```

## Architecture and Key Technologies

### Core Components
- **Package Manager**: chezmoi with Go templating for OS-specific configurations
- **Shell**: Fish shell with vi-mode enabled
- **Version Manager**: asdf for Node.js, Python (Miniconda), and Go
- **Runtime Installer**: Bun uses official installer (not asdf)
- **Terminal Multiplexer**: tmux with vi-mode and mobile device optimizations

### Template System
- Files ending in `.tmpl` use chezmoi's Go templating
- OS detection via `{{ .chezmoi.os }}` (darwin/linux)
- Platform-specific features controlled through templates
- Ubuntu-specific handling for tool names (batcat→bat, fdfind→fd)
- User configuration via `.chezmoi.toml.tmpl` (prompts for name/email in interactive mode)

### Directory Structure
- `private_dot_config/`: Configs that become `~/.config/`
- `dot_*`: Files that become `~/.*` (e.g., `dot_gitconfig.tmpl` → `~/.gitconfig`)
- Templates process during `chezmoi apply` based on OS and environment

### Installation Architecture
- **Minimal bootstrap**: `install.sh` only installs chezmoi and runs `chezmoi init`
- **Chezmoi scripts**: All tool installation happens via `.chezmoiscripts/`
  - `run_once_*` scripts run once for initial setup
  - `run_onchange_*` scripts re-run when tool versions change
  - Templates handle OS-specific logic
- **Tool installation**: Binary downloads to `~/.local/bin` when possible
- **Architecture detection**: Automatic for x86_64, arm64
- **Error handling**: Scripts continue on failure (e.g., Python/Conda ToS issue)

## Development Patterns

### Fish Functions
- Custom functions in `private_dot_config/private_fish/functions/`
- FZF integration functions prefixed with `f` (fcd, fgit, fgrep, fopen, fkill)
- Functions automatically loaded by Fish on startup

#### Key Fish Functions Reference
- **dotfiles** - Manage dotfiles (edit, diff, apply, push, pull, status)
- **tools** - Display all available tools with descriptions (--interactive, --table)
- **yank** - Copy to clipboard via OSC 52 (works over SSH)
- **ta** - Tmux session manager (attach or create)
- **mkcd** - Make directory and cd into it
- **backup** - Create timestamped backup
- **extract** - Extract any archive format
- **update** - Update system packages
- **ports** - Show listening ports
- **myip** - Display IP addresses
- **asdf-setup** - Install asdf plugins
- **asdf-install-latest** - Install latest versions
- **asdf-update** - Update all plugins

### Configuration Files
- Fish config: `private_dot_config/private_fish/config.fish.tmpl`
- Tmux config: `dot_tmux.conf`
- Git config: `dot_gitconfig.tmpl`
- Starship prompt: `private_dot_config/starship.toml`
- Tool versions: `dot_tool-versions.tmpl`

### Testing Approach
- `test.sh` verifies all tools are installed and accessible
- Tests check command availability, Fish functions, and configurations
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
- `CHEZMOI_USER_NAME`: Name for git config (avoids interactive prompt)
- `CHEZMOI_USER_EMAIL`: Email for git config (avoids interactive prompt)

### Cross-Platform Considerations
- macOS uses Homebrew for some dependencies
- Linux supports apt, dnf, and pacman package managers
- Binary downloads automatically detect CPU architecture
- Ubuntu requires special handling for renamed packages

### Known Issues
- Python/Miniconda installation may fail with "Terms of Service" error - the script continues without Python
- On Ubuntu, some tools have different names (bat→batcat, fd→fdfind) - handled via aliases

## Complete Tools Reference

### Installed Command-Line Tools
All tools are automatically installed via `.chezmoiscripts/run_onchange_02-install-tools.sh.tmpl`:

#### Core Tools
- **chezmoi** - Dotfiles manager
- **fish** - Modern shell with autosuggestions
- **asdf** - Version manager for Node.js, Python, Go

#### Modern CLI Replacements
- **eza** → ls (with icons, git info)
- **bat** → cat (syntax highlighting)
- **fd** → find (simpler, faster)
- **ripgrep (rg)** → grep (blazing fast)
- **zoxide (z)** → cd (learns your directories)
- **btop** → top (beautiful UI)
- **duf** → df (friendly disk usage)
- **dust** → du (intuitive disk analyzer)

#### Development Tools
- **fzf** - Fuzzy finder (Ctrl+R, Ctrl+T, Alt+C)
- **starship** - Cross-shell prompt with git info
- **atuin** - Better shell history with search
- **delta** - Beautiful git diffs
- **lazygit (lg)** - Git TUI
- **gh** - GitHub CLI
- **httpie (https)** - Friendly HTTP client
- **jq** - JSON processor
- **just** - Modern make/task runner
- **gum** - Pretty shell scripts
- **direnv** - Auto-load .envrc files
- **broot** - Interactive tree navigation
- **tldr** - Simplified man pages

#### Kubernetes Tools
- **kubectl** - Kubernetes CLI
- **kubectx** - Switch between contexts
- **kubens** - Switch between namespaces

#### Language Runtimes (via asdf)
- **Node.js** 22.11.0 (LTS)
- **Python** (Miniconda3-latest)
- **Go** 1.24.6
- **Bun** (via official installer, not asdf)

### Testing & Validation
Run `./test.sh` to verify all tools are installed correctly. Use `./test.sh --minimal` for faster testing without language runtime checks.