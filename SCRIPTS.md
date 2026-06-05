# Dotfiles Scripts Documentation

## Installation Scripts

### `install.sh`
Minimal bootstrap: installs chezmoi and runs `chezmoi init --apply`. It takes no CLI options — everything else (shells, mise, tools, languages) happens via the ordered scripts in `.chezmoiscripts/`.

**Usage:**
```bash
./install.sh
```

**Environment variables** (read by install.sh and the chezmoi scripts):
- `CI=true` - non-interactive mode; skips prompts and the login-shell step
- `QUICK_INSTALL=true` - skip language runtimes and Claude plugin setup
- `CHEZMOI_USER_NAME` / `CHEZMOI_USER_EMAIL` - pre-seed identity (defaults from git config)

**What an apply installs:**
- Zsh (default shell) and Fish configurations
- mise with Node.js, Python (via Miniconda), Go, Bun, Java
- Modern CLI tools (fzf, bat, fd, ripgrep, etc.)

### `setup-aliases.sh`
Creates symlinks for Ubuntu-specific tool names (batcat→bat, fdfind→fd).
Called by docker-test.sh; run manually on bare Ubuntu if needed.

## Test Scripts

### `test.sh`
Comprehensive test suite that verifies all tools are installed correctly.

**Usage:**
```bash
./test.sh
```

**Options:**
- `--minimal` - Run only core functionality tests

## Docker Testing

### `docker-test.sh`
Run installation and tests in an isolated Docker container.

**Usage:**
```bash
# Interactive mode (drops into shell)
./docker-test.sh

# CI mode (automated testing)
./docker-test.sh --ci
```

## Recommended Workflows

### Local Installation
```bash
# Full installation with languages
./install.sh

# Quick installation (no languages)
./install.sh --quick
```

### CI/CD Pipeline
```bash
# Run automated tests in Docker
./docker-test.sh --ci
```

### Development Testing
```bash
# Test in Docker interactively
./docker-test.sh
```

## Scripts to be Removed

The following scripts are redundant and will be removed:
- install-fast.sh (use `install.sh --quick`)
- install-quick.sh (use `install.sh --quick`)
- install-remaining.sh (not needed)
- test-minimal.sh (use `test.sh --minimal`)
- docker-test-ci.sh (use `docker-test.sh --ci`)
- docker-test-minimal.sh (redundant)
- docker-test-simple.sh (redundant)
- ci-test.sh (use `docker-test.sh --ci`)
- quick-test.sh (redundant)