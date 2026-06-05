# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Cross-platform dotfiles managed by [chezmoi](https://chezmoi.io/), targeting macOS and Linux, with modern CLI tool replacements. Two interactive shells are maintained in parallel feature-for-feature: **Zsh** (the default) and **Fish**. This repo also manages Claude Code's own config (see `dot_claude/`).

## Essential Commands

```bash
# Edit / apply locally (run from anywhere; `dotfiles` is a shell function, defined for both Zsh and Fish)
dotfiles edit          # cd to this source dir
dotfiles diff          # preview what `apply` would change
dotfiles apply         # apply to $HOME
dotfiles push / pull   # commit+push, or pull+apply

# Equivalent chezmoi primitives
chezmoi diff
chezmoi apply -v
chezmoi add ~/.config/fish/foo.fish   # pull an external file into this repo

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
- These compose: `private_dot_config/private_fish/config.fish.tmpl` → `~/.config/fish/config.fish`.
- `dot_claude/` → `~/.claude/` — this repo manages Claude Code's subagents (`agents/`), slash commands (`commands/`), hooks (`hooks/`), statusline, and a `create_settings.json` reference for the settings file.

### Templating and per-machine data
`.chezmoi.toml.tmpl` computes the `[data]` map consumed by every `.tmpl`. Key variables: `.chezmoi.os` (darwin/linux), `.chezmoi.arch`, `.brewPrefix`, `.packageManager`, and the **work-machine** vars `.isWork` / `.workHostname` (prompted once on a personal machine). Example use: `.chezmoiignore` drops the managed `.gitconfig` on the work host so `gh`'s credential-helper writes don't cause drift. In CI or when `CHEZMOI_USER_NAME` is set, prompts are skipped and personal/non-work defaults are used.

`.chezmoiignore` lists files that exist in the repo but are **not** deployed (README, CLAUDE.md, install/test scripts, OS-gated `conf.d/*.fish`). `.chezmoiremove` deletes obsolete files from `$HOME` on apply.

### Install & tool provisioning
`install.sh` is a minimal bootstrap: it only installs chezmoi and runs `chezmoi init --apply`. Everything else happens via ordered scripts in `.chezmoiscripts/`:
- `run_once_*` — one-time setup (Fish, Zsh, mise, tpm, bun); `run_once_after_*` runs at the end (recommends Zsh as login shell; never runs `chsh` itself).
- `run_onchange_*` — re-run **only when their content hash changes**. `run_onchange_after_05-install-tools.sh.tmpl` embeds `{{ include "private_dot_config/mise/config.toml.tmpl" | sha256sum }}` so editing the mise config re-triggers tool installation. It runs in the `after` pass (post-`03-install-languages`, post-`04-cleanup`) so node/npm exist for the npm-installed tools and freshly-installed binaries survive the cleanup sweep.

Tools come from two places — keep both in sync when adding/removing a tool:
1. **mise** (`private_dot_config/mise/config.toml.tmpl`) — language runtimes + the `aqua:` backend tools (the bulk of the CLI suite) + a couple of mise plugins (`television`). This is the source of truth for versions; do **not** hardcode versions in docs.
2. **`run_onchange_after_05-install-tools.sh.tmpl`** — tools *not* in the aqua registry, installed via Homebrew / apt-dnf-pacman / binary / cargo / npm: `btop`, `httpie`, `broot`, `tldr`, `pinentry`, `tmux`, `helix`, `worktrunk`, `biome`, plus macOS-only `eza` and `ktlint`.

Machine-local-only tools live in `~/.config/mise/conf.d/local.toml`, deliberately kept out of this repo.

### Shell layout (Zsh + Fish)
> **Invariant:** the two shells are kept feature-for-feature in sync. Any tool alias, shell function, or `tools` cheat-sheet entry must be edited in **both**. The repo-local `extend-dotfiles` skill encodes the full dual-shell checklist — use it.

- **Zsh** (default interactive shell):
  - *Entry points* — `~/.zshenv` (`dot_zshenv.tmpl`: PATH/env for all shells, incl. non-interactive) and `~/.zshrc` (`dot_zshrc.tmpl`: interactive setup).
  - *Loading* — functions (`private_dot_config/zsh/functions/*.zsh`) and `conf.d/*.zsh` (fzf, macos, greeting, motd) are **sourced** in a `for` loop by `.zshrc`, not autoloaded.
  - *Plugins* — the bits Fish ships built-in (autosuggestions, syntax-highlighting) plus `zsh-abbr` are cloned by chezmoi into `~/.config/zsh/plugins` via `.chezmoiexternal.toml.tmpl`; no plugin manager. (syntax-highlighting must be sourced last.)
  - *Unmanaged* — `~/.config/zsh/config.local.zsh`.
- **Fish** — under `private_dot_config/private_fish/`. Functions are autoloaded from `functions/`; `conf.d/` files load on startup (several `.tmpl`, OS-gated via `.chezmoiignore`). Unmanaged: `~/.config/fish/config.local.fish`.
- **Shared** — starship (prompt) and atuin (history) back both shells, so they behave identically. cmux self-wires its own zsh/fish integration.

## Conventions

- The canonical list of installed tools and shell functions is the `tools` function (defined in **both** `tools.zsh` and `tools.fish`) and the mise config — prefer those over re-listing here. README.md has the long-form human-facing tool descriptions.
- Scripts continue on non-fatal failures (e.g. Miniconda ToS) rather than aborting the whole apply.
- Renovate (`renovate.json`) opens PRs for mise tool versions, GitHub Actions, and binary versions pinned in scripts; minor/patch auto-merge, majors need review.
- This repo replaces traditional Unix tools: `ls`→eza, `cat`→bat, `find`→fd, `grep`→rg, `cd`→zoxide (z), `top`→btop, `df`→duf, `du`→dust.
