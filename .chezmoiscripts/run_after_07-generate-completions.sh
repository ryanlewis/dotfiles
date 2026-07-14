#!/bin/bash
# Generate zsh completion functions for tools that ship them as a subcommand.
# aqua/mise-installed binaries are bare executables — unlike brew packages they
# don't drop completion files into a site-functions dir, so we generate them
# here into ~/.config/zsh/completions (on fpath, see dot_zshrc.tmpl).
#
# Runs on every apply (not run_onchange: mise pins these tools to "latest", so
# a config-hash trigger would never see upgrades). Each generator is a few ms
# and a no-op unless its output changed. Shell startup is untouched: compinit
# autoloads from fpath on first use, so nothing here runs at rc time.
set -u

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

comp_dir="$HOME/.config/zsh/completions"
mkdir -p "$comp_dir"
changed=0

# generate <_funcname> <command...> — run the generator, install only on change
generate() {
    local file="$comp_dir/$1"
    shift
    local tmp
    tmp="$(mktemp)" || return 0
    if "$@" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        if ! cmp -s "$tmp" "$file" 2>/dev/null; then
            mv "$tmp" "$file"
            changed=1
            echo "  ↻ regenerated zsh completions: $1"
            return
        fi
    fi
    rm -f "$tmp"
}

command -v rg >/dev/null 2>&1 && generate _rg rg --generate=complete-zsh

# The cached zcompdump would keep serving stale completions for up to a day
# (compinit -C fast path in .zshrc) — drop it so the next shell rebuilds.
if [ "$changed" -eq 1 ]; then
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
fi

exit 0
