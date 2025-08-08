# Cross-Platform Dotfiles with Chezmoi

This repository contains my personal dotfiles managed by [chezmoi](https://chezmoi.io/), optimized for Fish shell and supporting both Linux and macOS.

## Features

- 🐟 Fish shell configuration with cross-platform support
- 🍎 macOS-specific optimizations (Homebrew, iTerm2, etc.)
- 🐧 Linux compatibility
- 🛠️ Useful Fish functions and utilities
- 📦 Template-based configuration for different environments
- 🔧 asdf version manager for Node.js, Python, and Go
- 🔍 Modern CLI tools: Complete suite of modern replacements for traditional Unix tools
- ⭐ Starship cross-shell prompt with git integration
- 📜 Atuin for enhanced shell history (better search, statistics, deduplication)

## Prerequisites

- Git
- curl or wget
- sudo access (for package installation)

## Installation

### One-Line Install

```bash
# Clone and run the install script
git clone https://github.com/yourusername/dotfiles ~/dev/dotfiles && cd ~/dev/dotfiles && ./install.sh
```

### Step-by-Step Install

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles ~/dev/dotfiles
   cd ~/dev/dotfiles
   ```

2. Run the install script:
   ```bash
   # Full installation (all tools and language runtimes)
   ./install.sh
   
   # Quick installation (tools only, no language runtimes)
   ./install.sh --quick
   
   # Non-interactive installation (for automation)
   ./install.sh --no-confirm
   ```

3. Restart your shell or start Fish:
   ```bash
   fish
   ```

### What the Install Script Does

The `install.sh` script handles the complete setup:

1. **Installs Fish shell** if not present
2. **Installs chezmoi** to `~/.local/bin`
3. **Sets up asdf** version manager
4. **Installs language runtimes** (Node.js, Python, Go via asdf; Bun via official installer)
5. **Installs modern CLI tools** (eza, bat, ripgrep, fzf, etc.)
6. **Applies dotfiles** using chezmoi
7. **Configures Fish** as your default shell (optional)

### Environment Variables

For non-interactive installation, you can set:
```bash
# Skip interactive prompts for chezmoi
export CHEZMOI_USER_NAME="Your Name"
export CHEZMOI_USER_EMAIL="your.email@example.com"

# Run installation
./install.sh --no-confirm
```

### Manual chezmoi Setup (Advanced)

If you prefer to use chezmoi directly:

```bash
# Install chezmoi (if not already installed)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Initialize from this repository
chezmoi init --apply ~/dev/dotfiles

# Or for non-interactive:
CHEZMOI_USER_NAME="Your Name" CHEZMOI_USER_EMAIL="you@example.com" \
  chezmoi init --apply ~/dev/dotfiles
```

## Usage

### Common Commands

- `chezmoi diff` - See what changes would be made
- `chezmoi apply` - Apply the configuration
- `chezmoi add ~/.config/fish/newfile.fish` - Add a new file
- `chezmoi edit ~/.config/fish/config.fish` - Edit a managed file
- `chezmoi update` - Pull latest changes and apply

### Fish Functions

This configuration includes several useful Fish functions:

- `mkcd <dir>` - Create a directory and cd into it
- `backup <file>` - Create a timestamped backup of a file
- `extract <archive>` - Extract various archive formats
- `update` - Update system packages (brew/apt/dnf/pacman)
- `ports` - Show listening ports
- `myip` - Display local and public IP addresses
- `asdf-setup` - Install and configure asdf plugins for Node.js, Python, and Go
- `asdf-install-latest` - Install latest stable versions of all tools
- `asdf-update` - Update asdf and all plugins

#### FZF-Powered Functions

- `fcd` - Fuzzy change directory with preview
- `fopen` - Fuzzy find and open file in editor
- `fkill` - Fuzzy find and kill processes
- `fgrep <term>` - Fuzzy grep with file preview
- `fgit <cmd>` - Interactive git operations:
  - `fgit add` - Stage files interactively
  - `fgit checkout` - Checkout branches with preview
  - `fgit log` - Browse git log with commit preview
  - `fgit diff` - View file diffs interactively

### macOS-Specific Features

When running on macOS, additional features are enabled:

- Homebrew integration
- GNU coreutils in PATH (if installed)
- macOS-specific aliases:
  - `flushdns` - Flush DNS cache
  - `ql <file>` - Quick Look preview
  - `showfiles/hidefiles` - Toggle hidden files in Finder
  - `cleanup` - Remove .DS_Store files

### Modern CLI Tools

This configuration includes a comprehensive suite of modern CLI tools:

#### File & Directory Tools
- **[eza](https://github.com/eza-community/eza)** - Modern `ls` replacement
  - Icons, colors, git integration, tree view
  - Aliased to replace all `ls` variants
- **[fd](https://github.com/sharkdp/fd)** - Better `find`
  - Simple syntax, respects .gitignore
  - Default file finder for fzf
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Better `grep`
  - Extremely fast, respects .gitignore
  - Powers the `fgrep` function
- **[bat](https://github.com/sharkdp/bat)** - Better `cat`
  - Syntax highlighting, line numbers
  - File previews in fzf
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smarter `cd`
  - Learns your most used directories
  - Jump with partial names

#### System Monitoring
- **[btop](https://github.com/aristocratos/btop)** - Better `top`/`htop`
  - Beautiful terminal UI
  - Aliased to replace `top` and `htop`
- **[duf](https://github.com/muesli/duf)** - Better `df`
  - User-friendly disk usage display
- **[dust](https://github.com/bootandy/dust)** - Better `du`
  - Intuitive disk usage analyzer

#### Development Tools
- **[lazygit](https://github.com/jesseduffield/lazygit)** - Terminal UI for git
  - Interactive staging, branching, merging
  - Launch with `lg`
- **[delta](https://github.com/dandavison/delta)** - Better git diffs
  - Syntax highlighting, side-by-side view
  - Auto-configured in gitconfig
- **[gh](https://cli.github.com/)** - GitHub CLI
  - Manage PRs, issues from terminal
- **[httpie](https://httpie.io/)** - Better `curl`
  - Human-friendly HTTP client
  - `https` alias for HTTPS requests
- **[jq](https://stedolan.github.io/jq/)** - JSON processor
  - Query and manipulate JSON data
- **[just](https://github.com/casey/just)** - Modern `make`
  - Simpler command runner

#### Shell Enhancements
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder
  - Ctrl+R (history), Ctrl+T (files), Alt+C (directories)
  - Powers many custom functions
- **[starship](https://starship.rs/)** - Cross-shell prompt
  - Fast, customizable, git-aware
  - Pre-configured with icons
- **[atuin](https://github.com/atuinsh/atuin)** - Better shell history
  - Advanced fuzzy search, statistics, intelligent deduplication
- **[direnv](https://direnv.net/)** - Directory environments
  - Auto-load .envrc files
- **[broot](https://github.com/Canop/broot)** - Better `tree`
  - Navigate directories efficiently
- **[tldr](https://tldr.sh/)** - Simplified man pages
  - Quick command examples

### Version Management with asdf

This configuration includes [asdf](https://asdf-vm.com/) for managing programming language versions. The following tools are pre-configured:

- Node.js
- Python  
- Go

Note: Bun is installed separately using its official installer for always getting the latest version.

To set up asdf after installation:

```bash
# Install asdf plugins and tools
asdf-setup
asdf install

# Or install latest versions
asdf-install-latest
```

## Customization

### Local Configuration

Create `~/.config/fish/config.local.fish` for machine-specific configuration that won't be managed by chezmoi.

### Templates

This repository uses chezmoi templates to handle OS-specific differences. Key template variables:

- `{{ .chezmoi.os }}` - "darwin" or "linux"
- `{{ .chezmoi.arch }}` - System architecture
- `{{ .brewPrefix }}` - Homebrew prefix path
- `{{ .packageManager }}` - System package manager

## Directory Structure

```
~/dev/dotfiles/
├── .chezmoi.toml.tmpl          # Chezmoi configuration template
├── .chezmoiignore              # Files to ignore by OS
├── private_dot_config/
│   └── private_fish/
│       ├── config.fish.tmpl    # Main Fish config
│       ├── functions/          # Fish functions
│       └── conf.d/             # Fish conf.d files
└── README.md                   # This file
```

## Testing with Docker

You can test the dotfiles installation in a clean Docker environment:

### Quick Test
```bash
# Run the interactive test script
./docker-test.sh

# Inside the container:
cd /home/testuser/dev/dotfiles
./install.sh
fish
./test.sh  # Run the test suite
```

### Manual Docker Commands
```bash
# Build the test image
docker build -f Dockerfile.test -t dotfiles-test .

# Run container with mounted dotfiles
docker run -it --rm -v "$(pwd):/home/testuser/dev/dotfiles:ro" dotfiles-test

# Or use docker-compose
docker-compose up -d dotfiles-test
docker exec -it dotfiles-test fish
```

### Test Script
The `test.sh` script verifies all tools are installed correctly:
- Checks all CLI tools are available
- Verifies Fish functions exist
- Confirms configurations are in place
- Tests asdf plugins

## CI/CD

This repository includes automated testing via GitHub Actions:

### Continuous Integration
- Tests on Ubuntu 22.04 and 24.04
- Tests on macOS 13 and 14
- Docker-based testing
- Full tool installation verification

### Running in CI Mode
```bash
# Install with CI mode (non-interactive)
./install.sh --ci

# Or just skip confirmations
./install.sh --no-confirm
```

Environment variables for CI:
- `CI=true` - Automatically detected by GitHub Actions
- `CHEZMOI_USER_NAME` - Name for git config
- `CHEZMOI_USER_EMAIL` - Email for git config

## Troubleshooting

### Installation Issues

#### Python/Miniconda fails with "Terms of Service" error
This is a known issue with Miniconda requiring ToS acceptance. The script will continue without Python. To fix:
```bash
# Accept Conda ToS manually
~/.asdf/installs/python/miniconda3-latest/bin/conda init
~/.asdf/installs/python/miniconda3-latest/bin/conda config --set auto_activate_base false
```

#### Script fails with "command not found" 
Ensure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

#### Fish doesn't start with correct configuration
```bash
# Re-apply dotfiles
chezmoi apply -v

# Install Fisher plugins manually
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fish -c "fisher install PatrickF1/fzf.fish"
```

#### Tools not found after installation
```bash
# Source asdf in current shell
source ~/.asdf/asdf.sh

# Or start a new Fish shell
fish
```

## Automated Dependency Updates with Renovate Bot

This repository uses [Renovate Bot](https://docs.renovatebot.com/) to automatically keep dependencies up-to-date. Renovate creates pull requests when new versions are available.

### What Renovate Updates

#### 1. **asdf Tool Versions** (`dot_tool-versions.tmpl`)
- Node.js versions
- Go versions  
- Bun versions
- Python/Miniconda versions

#### 2. **GitHub Actions** (`.github/workflows/*.yml`)
- Action versions (e.g., `actions/checkout`)
- GitHub-hosted runner versions

#### 3. **Binary Tools in install.sh**
- asdf version manager
- fzf (fuzzy finder)
- delta (git diff viewer)
- atuin (shell history)
- just (command runner)
- kubectx/kubens (Kubernetes tools)
- duf (disk usage)
- dust (du alternative)

### How It Works

1. **Scheduled Runs**: Renovate runs weekly on Mondays at 3am UTC
2. **Pull Requests**: Creates PRs for each dependency update
3. **Auto-merge**: Minor and patch updates are auto-merged if tests pass
4. **Major Updates**: Require manual review and approval

### Manual Trigger

To manually run Renovate:
1. Go to Actions tab
2. Select "Renovate" workflow
3. Click "Run workflow"
4. Optionally set debug log level

### Configuration

- Main config: `renovate.json`
- GitHub workflow: `.github/workflows/renovate.yml`

### Setup Requirements

For contributors who fork this repo:
1. Create a GitHub Personal Access Token with `repo` scope
2. Add it as `RENOVATE_TOKEN` in repository secrets
3. Renovate will start creating update PRs automatically

## Contributing

Feel free to fork and customize for your own use!

## Tool Versions

Last updated: January 2025

### Core Tools
- asdf: v0.14.1
- chezmoi: Latest from official installer

### CLI Tools
- delta: 0.18.2
- dust: 1.2.2
- Other tools: Latest available from package managers

### Programming Languages
- Node.js: 22.11.0 (LTS) - via asdf
- Python: miniconda3-latest - via asdf
- Go: 1.24.6 - via asdf
- Bun: latest - via official installer

## License

MIT