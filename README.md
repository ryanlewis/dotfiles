# Cross-Platform Dotfiles with Chezmoi

This repository contains my personal dotfiles managed by [chezmoi](https://chezmoi.io/), supporting both Linux and macOS. Zsh is the shell.

## Features

- 🦓 Zsh configuration with cross-platform support
- 🍎 macOS-specific optimizations (Homebrew, Ghostty, etc.)
- 🐧 Linux compatibility
- 🛠️ Useful shell functions and utilities
- 📦 Template-based configuration for different environments
- 🔧 mise for language runtimes (Node.js, Python, Go, Bun, Java)
- 🌊 mise aqua backend for the modern CLI suite (bat, fd, eza, kubectl, gh, etc.)
- 🔍 Modern CLI tools: Complete suite of replacements for traditional Unix tools
- ⭐ Starship cross-shell prompt with git integration
- 📜 Atuin for enhanced shell history (better search, statistics, deduplication)
- 🧹 Automatic cleanup of old tool installations

## Prerequisites

- Git
- curl or wget
- sudo access (for package installation)

## Installation

### Quick Install (Recommended)

```bash
# One-liner installation
curl -fsLS https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash
```

Or if you prefer using `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash
```

### Alternative: Using Chezmoi Directly

If you already have chezmoi installed:

```bash
chezmoi init --apply ryanlewis/dotfiles
```

### Environment Variables

Control installation behavior with these environment variables:

```bash
# Skip language runtimes (Node.js, Python, Go)
QUICK_INSTALL=true curl -fsLS https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash

# Provide git config to avoid prompts
CHEZMOI_USER_NAME="Your Name" CHEZMOI_USER_EMAIL="you@example.com" \
  curl -fsLS https://raw.githubusercontent.com/ryanlewis/dotfiles/main/install.sh | bash
```

## What Gets Installed

The installation process automatically sets up:

1. **Zsh** - Interactive shell with plugins and abbreviations
2. **chezmoi** - Dotfiles manager
3. **mise** - Universal version manager
4. **Modern CLI tools**:
   - `eza` - Better `ls`
   - `bat` - Better `cat` with syntax highlighting
   - `ripgrep` - Better `grep`
   - `fd` - Better `find`
   - `fzf` - Fuzzy finder
   - `zoxide` - Smarter `cd`
   - `starship` - Cross-shell prompt
   - `btop` - Better `top`
   - `duf` - Better `df`
   - `dust` - Better `du`
   - `gum` - Pretty shell scripts
   - `kubectl` - Kubernetes CLI
   - `kubectx` - K8s context switcher
   - `kubens` - K8s namespace switcher
   - And more...
5. **Language runtimes** (optional):
   - Node.js (via mise)
   - Python/Miniconda (via mise)
   - Go (via mise)
   - Bun (via mise)

## Usage

### Common Commands

- `chezmoi diff` - See what changes would be made
- `chezmoi apply` - Apply the configuration
- `chezmoi add ~/.config/zsh/functions/foo.zsh` - Add a new file
- `chezmoi edit ~/.zshrc` - Edit a managed file
- `chezmoi update` - Pull latest changes and apply

### Zsh Functions

This configuration includes several useful Zsh functions:

- `mkcd <dir>` - Create a directory and cd into it
- `backup <file>` - Create a timestamped backup of a file
- `extract <archive>` - Extract various archive formats
- `update` - Update system packages (brew/apt/dnf/pacman)
- `ports` - Show listening ports
- `myip` - Display local and public IP addresses
- `yank` - Copy text to clipboard via OSC 52 (works over SSH)
- `mise-setup` - Show configured mise tools and install hints
- `mise-install-latest` - Install latest stable versions of all tools
- `mise-update` - Update mise and all plugins

#### Clipboard Function: yank

The `yank` function enables clipboard access from anywhere, even over SSH:

```bash
# Copy command output
git diff | yank
cat ~/.ssh/id_rsa.pub | yank
echo "some text" | yank

# Works over SSH - copies to your local clipboard!
ssh server "cat /var/log/nginx/error.log | yank"
```

**Why use yank?**
- Works over SSH without X11 forwarding
- Works in tmux/screen sessions  
- Universal solution across different terminals (iTerm2, Terminal.app, Alacritty, Windows Terminal, etc.)
- No need for platform-specific tools (pbcopy/xclip)

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
  - `showdesktop/hidedesktop` - Toggle desktop icons
  - `afk` - Start the screensaver (lock away from keyboard)
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
- **[worktrunk](https://github.com/worktrunk/worktrunk)** - Git worktree manager
  - Create/switch worktrees fast; launched via `wt` (and the `wsc` abbreviation)
- **[biome](https://biomejs.dev/)** - JS/TS formatter and linter
  - Single fast toolchain for formatting and linting
- **[uv](https://github.com/astral-sh/uv)** - Fast Python package/project manager
- **[helix](https://helix-editor.com/)** - Modal editor with LSP built in
  - Launched via `hx`; resolved as `$EDITOR` when present
- **[ktlint](https://pinterest.github.io/ktlint/)** - Kotlin linter/formatter (macOS only)

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

#### Container & Kubernetes Tools
- **[kubectl](https://kubernetes.io/docs/reference/kubectl/)** - Kubernetes CLI
  - Manage Kubernetes clusters
- **[kubectx](https://github.com/ahmetb/kubectx)** - Context switcher
  - Quickly switch between Kubernetes contexts
- **[kubens](https://github.com/ahmetb/kubectx)** - Namespace switcher
  - Quickly switch between Kubernetes namespaces

### Version Management with mise

This configuration includes [mise](https://mise.jdx.dev/) for managing:

**Language Runtimes** (5 tools):
- Node.js (LTS)
- Python (via Miniconda)
- Go
- Bun
- Java (Eclipse Temurin LTS)

**CLI Tools via the mise aqua backend**:
- Modern CLI replacements: bat, fd, eza, ripgrep, zoxide, duf, dust
- Development tools: fzf, starship, atuin, delta, lazygit, gh, jq, just, gum, direnv, uv
- Kubernetes tools: kubectl, kubectx, kubens
- AWS tools: granted (`assume`)
- Fuzzy finder TUI: television (`tv`, via a mise plugin)

Tools outside the aqua registry (btop, httpie, broot, tldr, pinentry, tmux, helix,
worktrunk, biome, and macOS-only eza/ktlint) are installed by
`.chezmoiscripts/run_onchange_after_05-install-tools.sh.tmpl`.

> The exact tool list and versions track `private_dot_config/mise/config.toml.tmpl`, which is the source of truth.

All tools are automatically installed via `~/.config/mise/config.toml` when you run:

```bash
# Install all configured tools (languages + CLI tools)
mise install

# Or install latest stable versions
mise-install-latest
```

**Note:** Old installations (Homebrew, apt packages, binaries) are automatically cleaned up after mise aqua setup.

## Development

### Making Changes to Dotfiles

After installation, your dotfiles are managed by chezmoi. To make changes:

```bash
# Go to chezmoi's source directory
chezmoi cd

# Edit files directly
vim dot_zshrc.tmpl

# Preview changes
chezmoi diff

# Apply changes locally
chezmoi apply

# Commit and push
git add -A
git commit -m "Update zsh config"
git push
```

Or use the included `dotfiles` function:

```bash
dotfiles edit     # Go to source directory
dotfiles diff     # Preview changes
dotfiles apply    # Apply locally
dotfiles push     # Commit and push all changes
dotfiles pull     # Pull latest from GitHub
```

### Updating from GitHub

On any machine with your dotfiles installed:

```bash
chezmoi update    # Pull latest changes and apply them
```

## Customization

### Local Configuration

Create `~/.config/zsh/config.local.zsh` for machine-specific configuration that won't be managed by chezmoi.

### Zsh

Zsh is the login shell (the provisioning script recommends it on fresh machines; `chsh -s $(which zsh)` to switch an existing one). It comprises:

- `~/.zshenv` — PATH/environment for all shells (the non-interactive half).
- `~/.zshrc` — interactive config: vi mode, completions, abbreviations, tool inits (mise, zoxide, fzf, atuin, starship, direnv, broot), aliases, and the MOTD/greeting.
- `~/.config/zsh/functions/*.zsh` — one function per file (`mkcd`, `extract`, `fcd`, `fgit`, `ca`, `crpr`, `tools`, …).
- `~/.config/zsh/conf.d/*.zsh` — fzf options, macOS extras, greeting, and MOTD.

The prompt (starship) and history (atuin) round out the setup.

Plugins (autosuggestions, syntax highlighting) plus `zsh-abbr` are fetched by chezmoi into `~/.config/zsh/plugins` (see `.chezmoiexternal.toml`) — there is no separate plugin manager.

Try it without switching: just run `zsh`. To make it your login shell when ready: `chsh -s "$(command -v zsh)"`.

### Templates

This repository uses chezmoi templates to handle OS-specific differences. Key template variables:

- `{{ .chezmoi.os }}` - "darwin" or "linux"
- `{{ .chezmoi.arch }}` - System architecture
- `{{ .brewPrefix }}` - Homebrew prefix path
- `{{ .packageManager }}` - System package manager

## Directory Structure

The chezmoi source directory lives at `~/.local/share/chezmoi` (run `chezmoi cd`
to jump there; `~/dev/dotfiles` is only the mount path used by `docker-test.sh`).

```
chezmoi source/
├── .chezmoi.toml.tmpl              # Per-machine data (prompts, .isWork, etc.)
├── .chezmoiignore                  # Files present in the repo but not deployed
├── .chezmoiremove                  # Files chezmoi deletes from $HOME on apply
├── .chezmoiexternal.toml.tmpl      # Externally-fetched files (zsh plugins)
├── .chezmoiscripts/                # Ordered run_once / run_onchange install scripts
├── dot_zshenv.tmpl                 # Zsh env for all shells (PATH, etc.)
├── dot_zshrc.tmpl                  # Main Zsh interactive config
├── dot_gitconfig.tmpl              # Git config (delta, etc.)
├── dot_tmux.conf                   # tmux configuration
├── dot_inputrc / dot_lesskey       # readline / less key bindings
├── dot_claude/                     # Claude Code config (agents, commands, hooks, statusline)
├── private_dot_config/
│   ├── zsh/                        # functions/, conf.d/
│   ├── mise/                       # mise config (tool + runtime source of truth)
│   ├── ghostty/ helix/ lazygit/    # per-tool configs
│   ├── starship.toml.tmpl          # shared prompt
│   └── tmux/ worktrunk/            # tmux helper scripts, worktrunk config
├── private_dot_gnupg/              # gpg-agent config
├── install.sh test.sh docker-test.sh setup-aliases.sh
├── Dockerfile renovate.json
└── README.md CLAUDE.md SCRIPTS.md  # docs (not deployed)
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
zsh
./test.sh  # Run the test suite
```

### Manual Docker Commands
```bash
# Build the test image
docker build -f Dockerfile -t dotfiles-test .

# Run container with mounted dotfiles
docker run -it --rm -v "$(pwd):/home/testuser/dev/dotfiles:ro" dotfiles-test
```

> `./docker-test.sh` (and `./docker-test.sh --ci`) wrap these commands; there is
> no `Dockerfile.test` or docker-compose file.

### Test Script
The `test.sh` script verifies all tools are installed correctly:
- Checks all CLI tools are available
- Verifies Zsh functions exist
- Confirms configurations are in place
- Tests mise tools

## CI/CD

This repository includes automated testing via GitHub Actions:

### Continuous Integration
- Tests on Ubuntu 24.04 and macOS 26 (GitHub-hosted runners)
- Full tool installation verification (`install.sh` + `test.sh`)
- Docker-based testing is available locally via `./docker-test.sh`

### Running in CI Mode
install.sh takes no CLI flags; CI behaviour is driven by environment variables.
```bash
# Non-interactive install (skips prompts and the login-shell step)
CI=true ./install.sh

# Non-interactive and skip language runtimes
CI=true QUICK_INSTALL=true ./install.sh
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
~/.local/share/mise/installs/python/miniconda3-latest/bin/conda init
~/.local/share/mise/installs/python/miniconda3-latest/bin/conda config --set auto_activate_base false
```

#### Script fails with "command not found" 
Ensure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

#### Zsh doesn't start with correct configuration
```bash
# Re-apply dotfiles
chezmoi apply -v
```
There is no plugin manager to set up: fzf key bindings come from `conf.d/fzf.zsh`
(and `fzf --zsh` in `~/.zshrc`), and every CLI tool is provided by mise. If a tool
is missing, ensure mise is active (`eval "$(mise activate bash)"`) and re-run
`chezmoi apply -v`.

#### Tools not found after installation
```bash
# Activate mise in current shell
eval "$(mise activate bash)"

# Or start a new Zsh shell
zsh
```

## Automated Dependency Updates with Renovate Bot

This repository uses [Renovate Bot](https://docs.renovatebot.com/) to automatically keep dependencies up-to-date. Renovate creates pull requests when new versions are available.

### What Renovate Updates

#### 1. **mise Tool Versions** (`private_dot_config/mise/config.toml.tmpl`)
- Node.js versions
- Go versions  
- Bun versions
- Python/Miniconda versions

#### 2. **GitHub Actions** (`.github/workflows/*.yml`)
- Action versions (e.g., `actions/checkout`)
- GitHub-hosted runner versions

#### 3. **Pinned binaries in the install-tools script** (`.chezmoiscripts/run_onchange_after_05-install-tools.sh.tmpl`)
- btop (system monitor)
- tealdeer / tldr (man-page examples)
- broot (tree navigation)

These are the only tools with hardcoded version pins; everything else tracks
`latest` (or a pinned version) via the mise config above. install.sh itself is a
flagless bootstrap and contains no version pins.

### How It Works

1. **Automated Runs**: Renovate app runs automatically on its schedule
2. **Pull Requests**: Creates PRs for each dependency update with conventional commits
3. **Auto-merge**: Minor and patch updates are auto-merged if tests pass
4. **Major Updates**: Require manual review and approval

### Configuration

- Main config: `renovate.json`
- Managed by: GitHub Renovate App (no additional setup needed)

### For Contributors

If you fork this repo, you'll need to:
1. Install the [Renovate GitHub App](https://github.com/apps/renovate) on your fork
2. Renovate will automatically detect the configuration and start creating PRs

## Contributing

Feel free to fork and customize for your own use!

## Tool Versions

Last updated: June 2026

The authoritative version list is `private_dot_config/mise/config.toml.tmpl`; Renovate keeps it current. CLI tools track `latest`, so only the pinned language runtimes are listed here.

### Core Tools
- chezmoi: latest from official installer
- mise: latest

### Programming Languages (pinned via mise)
Node.js, Python (miniconda3), Go, Bun, and Java (Eclipse Temurin LTS) — exact pinned versions live in `private_dot_config/mise/config.toml.tmpl`, the source of truth, and are bumped automatically by Renovate.

## License

MIT
