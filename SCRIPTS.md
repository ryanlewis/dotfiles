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
- Zsh configuration
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

## Benchmarking

Foundation for the shell-startup tuning routine (issue #61). `hyperfine` is
bootstrapped on demand (PATH, else a transient `mise x`) — it is deliberately
**not** a managed dotfiles tool.

### `scripts/bench-startup.sh`
Benchmark interactive zsh startup latency, **warm** (caches populated) and
**cold** (`_evalcache` init dir + compinit `zcompdump` busted each run).

**Usage:**
```bash
scripts/bench-startup.sh                              # hyperfine summary + warm/cold table
scripts/bench-startup.sh --json bench/baseline.json   # also write a combined JSON result
scripts/bench-startup.sh --runs 50 --warmup 5         # override run counts
```

### `scripts/profile-startup.sh`
Attribute startup time to each function/sourced segment via `zsh/zprof`
(compinit, plugin sourcing, each cached tool-init, conf.d/* and functions/*).

**Usage:**
```bash
scripts/profile-startup.sh          # warm
scripts/profile-startup.sh --cold   # bust caches first
```

See `bench/README.md` for what the numbers mean and the machine-specific caveat.

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

# Quick installation (no languages) — controlled by an env var, not a flag
QUICK_INSTALL=true ./install.sh
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