---
name: extend-dotfiles
description: >-
  Add a CLI tool or a Fish function to Ryan's chezmoi dotfiles repo so it lands
  in every place it needs to — install source, README, test.sh, and the `tools`
  function — instead of just one. Use this whenever working in the dotfiles repo
  (chezmoi source dir, ~/.local/share/chezmoi) and the task is "add/install
  <tool>", "wire up <tool>", "add a fish function for X", "make <X> a function",
  or removing one of those. The whole point is that a tool or function lives in
  several files that drift apart if you only edit one; this skill keeps them in
  sync. Trigger it even when the user just says "add ripgrep" or "add a function
  to do X" without naming chezmoi, as long as you're in this repo.
---

# Extending the dotfiles

This repo is a chezmoi-managed dotfiles tree. Adding a CLI tool or a Fish
function is not a one-file edit: the same tool or function is referenced in
several places that exist for different reasons (install, test, docs, the
in-shell `tools` cheat-sheet). If you touch only one, the repo drifts — CI
catches the missing `test.sh` entry, but README and the `tools` function rot
silently. This skill exists to make the *complete* set of edits every time.

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

After the install source, update the three sync points so the tool is tested,
documented, and discoverable:

- **`test.sh`** — add `check_command <bin>` next to the related tools (dev tools,
  k8s, etc.). Use the binary name a user actually runs (`http` for httpie, `rg`
  for ripgrep). If the binary has a different name on Ubuntu (like bat→batcat,
  fd→fdfind), follow the existing `command -v X || command -v Y` pattern instead.
- **`README.md`** — add a bullet in the right group under "Modern CLI Tools"
  (File & Directory / System Monitoring / Development Tools / etc.), matching the
  `**[name](url)** - one-liner` format. If you added an aqua tool, also bump the
  aqua tool count mentioned in the Features list and the mise section.
- **`tools` function** — `private_dot_config/private_fish/functions/tools.fish`
  lists every tool **twice**: once in the `tools_data` array (drives the
  `--interactive` and `--table` modes) and once in the hand-written colourful
  echo block (the default output). Add the tool to *both*, in the matching
  category (Core / Replace / Custom / FZF / Dev / Kubernetes). This double-entry
  is easy to half-do — check you got both.

**If the tool is a drop-in replacement for a traditional command** (it belongs
in the `Replace` category — e.g. procs→ps, the way eza→ls, bat→cat, dust→du
already work), add a shell alias too, otherwise the replacement is installed but
nobody actually uses it. Aliases live in
`private_dot_config/private_fish/config.fish.tmpl`, each guarded so it only
binds when the tool is on PATH:

```
{{- if lookPath "procs" }}
alias ps="procs"
{{- end }}
```

Match the surrounding aliases (`alias df="duf"`, `alias du="dust"`). Skip this
for tools that aren't replacing anything — most Dev/Custom tools don't get an
alias.

## Adding a Fish function

1. **Create the function file** at
   `private_dot_config/private_fish/functions/<name>.fish`. Functions here are
   autoloaded by filename, so the file name must equal the function name. Follow
   the house style: `function <name> --description "..."`, and for anything with
   options, a `--help/-h` branch (see `tools.fish`, `extract.fish`). If the body
   needs per-OS or templated values, name it `<name>.fish.tmpl` and OS-gate it in
   `.chezmoiignore` the way `update.fish.tmpl` is handled.
2. **`test.sh`** — add `check_fish_function <name>` in the "Checking Fish
   functions" block.
3. **`README.md`** — add a bullet under "Fish Functions" (or the FZF-powered
   sub-list if it's an fzf wrapper), matching the `` `name <args>` - description ``
   style.
4. **`tools` function** — add it to both places in `tools.fish` (the `tools_data`
   array and the echo block), under the Custom or FZF category as appropriate.

## Removing a tool or function

Reverse the same checklist: drop it from the install source, `test.sh`,
`README.md`, and both spots in `tools.fish`. If a removed file might still exist
in `$HOME` on machines that already applied it, add it to `.chezmoiremove` so it
gets cleaned up on next apply. For a deleted function file, that's the function
path under `~/.config/fish/functions/`.

## Verify before you're done

The edits are only "done" once they're internally consistent. Confirm:

- `dotfiles diff` (or `chezmoi diff`) shows the changes you expect and nothing
  spurious — for an aqua tool you should see the re-triggered install script.
- `./test.sh --minimal` passes (skips slow language-runtime checks). A missing
  `check_command`/`check_fish_function` is the most common slip; this catches it.
- Grep the repo for the tool/function name to make sure you didn't miss a
  reference: `rg -n '<name>'` across README, test.sh, and tools.fish should show
  it everywhere it belongs and nowhere stale.

## The sync-point checklist

Adding a **CLI tool** touches: install source (mise aqua config *or*
install-tools script) → `test.sh` → `README.md` → `tools.fish` (×2) → **plus a
guarded alias in `config.fish.tmpl` if it's a `Replace`-category tool**. Adding a
**Fish function** touches: the new `functions/<name>.fish` → `test.sh` →
`README.md` → `tools.fish` (×2). Miss one and the repo is inconsistent — run the
verify step.
