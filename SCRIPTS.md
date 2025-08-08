# Dotfiles Scripts Documentation

## Installation Scripts

### `install.sh`
Main installation script with full language runtime support.

**Usage:**
```bash
./install.sh [options]
```

**Options:**
- `--ci` - Run in CI mode (non-interactive)
- `--no-confirm` - Skip confirmation prompts
- `--quick` - Skip language runtimes, install pre-compiled tools only

**What it installs:**
- Fish shell
- asdf with Node.js, Python (via Miniconda), Go, Bun
- Modern CLI tools (fzf, bat, fd, ripgrep, etc.)
- All tools install to `~/.local/bin` when possible

### `setup-aliases.sh`
Creates symlinks for Ubuntu-specific tool names (batcat→bat, fdfind→fd).
Automatically called by install.sh on Linux.

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