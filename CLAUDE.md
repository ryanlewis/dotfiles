# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Cross-platform dotfiles managed by [chezmoi](https://chezmoi.io/), targeting macOS and Linux, with modern CLI tool replacements. **Zsh** is the interactive shell. This repo also manages Claude Code's own config (see `dot_claude/`).

## Essential Commands

```bash
# Edit / apply locally (run from anywhere; `dotfiles` is a Zsh function)
dotfiles edit          # cd to this source dir
dotfiles diff          # preview what `apply` would change
dotfiles apply         # apply to $HOME
dotfiles push / pull   # commit+push, or pull+apply

# Equivalent chezmoi primitives
chezmoi diff
chezmoi apply -v
chezmoi add ~/.config/zsh/foo.zsh   # pull an external file into this repo

# Test
./test.sh              # verify tools/functions/configs are present
./test.sh --minimal    # skip language-runtime checks (faster)
./docker-test.sh       # clean Ubuntu 26.04 container; --ci for non-interactive
```

There is no build step — "applying" is running the chezmoi templates against `$HOME`. CI (`.github/workflows/test.yml`) runs `install.sh` + `test.sh` across Ubuntu and macOS runners.

## Architecture

### chezmoi source-state naming (how files map to `$HOME`)
File/dir name prefixes are significant and determine the target path and behavior:
- `dot_foo` → `~/.foo`; `private_` → mode 0600; `executable_` → +x; `.tmpl` → rendered as a Go template.
- These compose: `private_dot_config/mise/config.toml.tmpl` → `~/.config/mise/config.toml` (rendered), and `dot_zshrc.tmpl` → `~/.zshrc`.
- `dot_claude/` → `~/.claude/` — this repo manages Claude Code's subagents (`agents/`), slash commands (`commands/`), hooks (`hooks/`), statusline, and a `create_settings.json` reference for the settings file.

### Templating and per-machine data
`.chezmoi.toml.tmpl` computes the `[data]` map consumed by every `.tmpl`. Key variables: `.chezmoi.os` (darwin/linux), `.chezmoi.arch`, `.brewPrefix`, `.packageManager`, the **work-machine** vars `.isWork` / `.workHostname`, and the **opt-in runtime** vars `.runtimeGo` / `.runtimeJava` / `.runtimePython` (all prompted once on a personal machine; default off). Example use: `.chezmoiignore` drops the managed `.gitconfig` on the work host so `gh`'s credential-helper writes don't cause drift. In CI or when `CHEZMOI_USER_NAME` is set, prompts are skipped and personal/non-work defaults are used.

`.chezmoiignore` lists files that exist in the repo but are **not** deployed (README, CLAUDE.md, install/test scripts, OS-gated launcher trees). `.chezmoiremove` deletes obsolete files from `$HOME` on apply.

### Install & tool provisioning
`install.sh` is a minimal bootstrap: it only installs chezmoi and runs `chezmoi init --apply`. Everything else happens via ordered scripts in `.chezmoiscripts/`:
- `run_once_*` — one-time setup (Zsh, mise, tpm, bun); `run_once_after_*` runs at the end (recommends Zsh as login shell, never running `chsh` itself — except it auto-`chsh`es to zsh when the current login shell is the now-retired fish).
- `run_onchange_*` — re-run **only when their content hash changes**. `run_onchange_after_05-install-tools.sh.tmpl` embeds `{{ include "private_dot_config/mise/config.toml.tmpl" | sha256sum }}` so editing the mise config re-triggers tool installation. It runs in the `after` pass (post-`03-install-languages`, post-`04-cleanup`) so node/npm exist for the npm-installed tools and freshly-installed binaries survive the cleanup sweep.

Tools come from two places — keep both in sync when adding/removing a tool:
1. **mise** (`private_dot_config/mise/config.toml.tmpl`) — the **core** runtime (`node`) + the `aqua:`/`npm:` backend tools (the bulk of the CLI suite) + a couple of mise plugins (`television`). This is the source of truth for versions; do **not** hardcode versions in docs. (**bun** is deliberately *not* in mise — it's installed by `run_once_04-install-bun.sh` and self-updates via `bun upgrade`.)
2. **`run_onchange_after_05-install-tools.sh.tmpl`** — tools *not* in the aqua registry, installed via Homebrew / apt-dnf-pacman / binary / cargo / npm: `btop`, `httpie`, `broot`, `tldr`, `pinentry`, `helix`, `worktrunk`, `biome`, plus macOS-only `eza` and `ktlint`.

**Opt-in language runtimes (Go/Java/Python):** removed from the default install. They live in the **managed** `private_dot_config/mise/conf.d/runtimes.toml.tmpl`, where each tool is gated by its `.runtime*` data var (selected at `chezmoi init`, default off — so VMs/CI stay lean). Version pins + `# renovate:` comments stay in that file, so add it to `renovate.json`'s `mise.managerFilePatterns` (already done). `run_onchange_after_03-install-languages` embeds both the `config.toml.tmpl` **and** the `runtimes.toml.tmpl` content hashes in its version-hash comment, so flipping a runtime selection *or* editing a runtime's pinned version/tools (e.g. bumping `go`, adding `gopls`) re-triggers `mise install`. mise never auto-uninstalls; `run_after_zz-mise-runtimes.sh.tmpl` prints the selection on every apply and flags installed-but-deselected runtimes (reminder-only — nothing is deleted).

Machine-local-only tools (e.g. `codex`, `sf`) live in the **unmanaged** `~/.config/mise/conf.d/local.toml`, deliberately kept out of this repo.

### Shell layout (Zsh)
Zsh is the only managed shell. When adding a tool alias, shell function, or `tools` cheat-sheet entry, keep the install source, `test.sh`, README, and the `tools` cheat-sheet in sync. The repo-local `extend-dotfiles` skill encodes the full checklist — use it.

- **Zsh** (interactive shell):
  - *Entry points* — `~/.zshenv` (`dot_zshenv.tmpl`: PATH/env for all shells, incl. non-interactive) and `~/.zshrc` (`dot_zshrc.tmpl`: interactive setup).
  - *Loading* — functions (`private_dot_config/zsh/functions/*.zsh`) and `conf.d/*.zsh` (fzf, macos, greeting, motd) are **sourced** in a `for` loop by `.zshrc`, not autoloaded.
  - *Plugins* — autosuggestions, syntax-highlighting, and `zsh-abbr` are cloned by chezmoi into `~/.config/zsh/plugins` via `.chezmoiexternal.toml.tmpl`; no plugin manager. (syntax-highlighting must be sourced last.)
  - *Unmanaged* — `~/.config/zsh/config.local.zsh`.
- **Shared** — starship (prompt) and atuin (history) back the shell. cmux self-wires its own zsh integration.

## Conventions

- The canonical list of installed tools and shell functions is the `tools` function (in `tools.zsh`) and the mise config — prefer those over re-listing here. README.md has the long-form human-facing tool descriptions.
- Scripts continue on non-fatal failures (e.g. Miniconda ToS) rather than aborting the whole apply.
- Renovate (`renovate.json`) opens PRs for mise tool versions, GitHub Actions, and binary versions pinned in scripts; minor/patch auto-merge, majors need review.
- This repo replaces traditional Unix tools: `ls`→eza, `cat`→bat, `find`→fd, `grep`→rg, `cd`→zoxide (z), `top`→btop, `df`→duf, `du`→dust.
