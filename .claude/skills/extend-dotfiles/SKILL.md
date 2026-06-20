---
name: extend-dotfiles
description: >-
  Add or remove a CLI tool or a shell function from these dotfiles, keeping it
  consistent across every place it lives — install source (mise aqua config or
  the install-tools script), test.sh, README, the `tools` cheat-sheet, and Zsh
  aliases — instead of editing one and letting the rest drift. Zsh is the only
  managed shell. Use whenever the task is adding, installing, or wiring up a
  tool, or adding/making a shell function — e.g. "add ripgrep", "wire up
  hyperfine", "add a function to do X".
---

# Extending the dotfiles

This repo is a chezmoi-managed dotfiles tree. Adding a CLI tool or a shell
function is not a one-file edit: the same tool or function is referenced in
several places that exist for different reasons (install, test, docs, the
in-shell `tools` cheat-sheet). If you touch only one, the repo drifts — CI
catches the missing `test.sh` entry, but README and the `tools` function rot
silently. This skill exists to make the *complete* set of edits every time.

> **One shell: Zsh.** Zsh is the only managed interactive shell. Shell-facing
> changes — a function, an alias, a `tools` entry — live in:
> - `dot_zshrc.tmpl` (aliases, setup)
> - `private_dot_config/zsh/functions/` (one function per file)
> - `private_dot_config/zsh/functions/tools.zsh` (the `tools` cheat-sheet)
>
> Install source, `test.sh`, and `README.md` are shell-agnostic.

Work out which of the two jobs you're doing, do the edits, then verify. Don't
guess at file contents — open each file and match its existing style.

## Adding a CLI tool

A tool can come from one of three places. Pick the right one first, because it
decides which install file you edit:

1. **mise aqua backend** — the default and strongly preferred. Versioned,
   cross-platform pre-built binaries, the source of truth for the bulk of the
   suite. Use this if the tool is in the aqua registry.
   - Check with `mise registry | rg <tool>` (or search pkgs.aqua.dev). The
     registry id looks like `owner/repo` or `owner/repo/subtool`.
   - Add a line to `private_dot_config/mise/config.toml.tmpl` under the
     "CLI tools via aqua backend" block:
     `"aqua:owner/repo" = "latest"`. Keep `latest` unless there's a concrete
     reason to pin (see the `granted` line for how a pin is annotated).
   - Editing this file re-triggers tool installation on next apply, because
     `run_onchange_02-install-tools.sh.tmpl` embeds its sha256.

2. **install-tools script** — for tools *not* in the aqua registry. Edit
   `.chezmoiscripts/run_onchange_02-install-tools.sh.tmpl` and add an install
   block in the existing style: guard with `if ! command -v <bin>`, then a
   chezmoi `{{ if eq .chezmoi.os "darwin" }}` Homebrew branch and a
   `{{ else if eq .chezmoi.os "linux" }}` branch covering apt/dnf/pacman with a
   binary/cargo/npm fallback. Copy the shape of a nearby tool (btop, httpie,
   broot) rather than inventing one.

3. **Split across both** — a few tools use aqua on one OS and Homebrew on the
   other. `eza` is the example: aqua on Linux (OS-gated with
   `{{ if ne .chezmoi.os "darwin" }}` in the mise config) and Homebrew on macOS
   (in the install script). Only do this when a tool genuinely isn't available
   one way on one platform.

Machine-local-only tools (something just this laptop needs) belong in
`~/.config/mise/conf.d/local.toml`, which is deliberately **not** in this repo —
don't add those here.

After the install source, update the sync points so the tool is tested,
documented, and discoverable:

- **`test.sh`** (shell-agnostic, edit once) — add `check_command <bin>` next to
  the related tools (dev tools, k8s, etc.). Use the binary name a user actually
  runs (`http` for httpie, `rg` for ripgrep). If the binary has a different name
  on Ubuntu (like bat→batcat, fd→fdfind), follow the existing
  `command -v X || command -v Y` pattern instead.
- **`README.md`** (edit once) — add a bullet in the right group under "Modern CLI
  Tools" (File & Directory / System Monitoring / Development Tools / etc.),
  matching the `**[name](url)** - one-liner` format. If you added an aqua tool,
  also bump the aqua tool count mentioned in the Features list and the mise
  section.
- **`tools` cheat-sheet — TWO spots.** The `tools` function lists every tool
  **twice**: once in the `tools_data` array (drives the `--interactive` and
  `--table` modes) and once in the hand-written colourful echo block (the
  default output). Add the tool to *both* spots in
  `private_dot_config/zsh/functions/tools.zsh`, in the matching category
  (Core / Replace / Custom / FZF / Dev / Kubernetes). This is easy to half-do —
  that's two edits, not one.

**If the tool is a drop-in replacement for a traditional command** (it belongs
in the `Replace` category — e.g. procs→ps, the way eza→ls, bat→cat, dust→du
already work), add a Zsh alias too, otherwise the replacement is installed but
nobody actually uses it. Add it in `dot_zshrc.tmpl`, in the modern-tool aliases
block, guarded so it only binds when the tool is on PATH:

  ```
  {{- if lookPath "procs" }}
  alias ps="procs"
  {{- end }}
  ```

Match the surrounding aliases (`alias df="duf"`, `alias du="dust"`). Skip this
for tools that aren't replacing anything — most Dev/Custom tools don't get an
alias.

## Adding a shell function

1. **Zsh** — `private_dot_config/zsh/functions/<name>.zsh`. These files are
   *sourced* in a loop by `.zshrc` (not autoloaded), so use a plain
   `<name>() { … }` definition. Match the house style: a leading `#` comment, and
   for anything with options a `--help/-h` branch (see `tools.zsh`,
   `extract.zsh`). If the body needs per-OS or templated values, name it
   `<name>.zsh.tmpl` and use in-file `{{ if eq .chezmoi.os … }}` conditionals
   (see `update.zsh.tmpl`).
2. **`test.sh`** — add `check_zsh_function <name>` in the zsh-functions block.
   This checks the function file exists under `~/.config/zsh/functions/`. The
   verify step below also syntax-checks the new `.zsh` file directly.
3. **`README.md`** — add a bullet under the functions section (or the FZF-powered
   sub-list if it's an fzf wrapper), matching the `` `name <args>` - description ``
   style.
4. **`tools` cheat-sheet** — add it to both spots in `tools.zsh` (the
   `tools_data` array and the echo block), under the Custom or FZF category as
   appropriate.

## Removing a tool or function

Reverse the same checklist: drop it from the install source, `test.sh`,
`README.md`, the Zsh alias (if any), and both spots in `tools.zsh`. For a removed
function, delete `private_dot_config/zsh/functions/<name>.zsh`.

If a removed file might still exist in `$HOME` on machines that already applied
it, add it to `.chezmoiremove` so it gets cleaned up on next apply — for a
deleted function that's `~/.config/zsh/functions/<name>.zsh`.

## Verify before you're done

The edits are only "done" once they're internally consistent. Confirm:

- `dotfiles diff` (or `chezmoi diff`) shows the changes you expect and nothing
  spurious — for an aqua tool you should see the re-triggered install script.
- New/changed zsh files parse: `zsh -n private_dot_config/zsh/functions/<name>.zsh`
  (and `zsh -n ~/.zshrc` after apply if you touched aliases there).
- `./test.sh --minimal` passes (skips slow language-runtime checks). A missing
  `check_command`/`check_zsh_function` is the most common slip; this catches it.
- Grep the repo for the tool/function name to make sure you didn't miss a
  reference: `rg -n '<name>'` should show it in README, test.sh, `tools.zsh`,
  and the function/alias location — and nowhere stale.

## The sync-point checklist

Adding a **CLI tool** touches: install source (mise aqua config *or*
install-tools script) → `test.sh` → `README.md` → `tools.zsh` (×2) → **plus a
guarded alias in `dot_zshrc.tmpl` if it's a `Replace`-category tool**.

Adding a **shell function** touches: `private_dot_config/zsh/functions/<name>.zsh`
→ `test.sh` → `README.md` → `tools.zsh` (×2).

Miss one and the repo is inconsistent — run the verify step.
