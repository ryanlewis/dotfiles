#!/usr/bin/env bash
# Fingerprint the observable surface of an interactive zsh — aliases, function
# names, abbreviations, key bindings, and non-default options — in a stable,
# sorted form. Diff two snapshots (before vs after a startup change) to enforce
# the tuning routine's hard "no behaviour change" guardrail: every alias,
# function, abbreviation and binding must survive an optimisation.
#
# test.sh checks that specific named functions/tools exist; this additionally
# pins aliases, abbreviations, key bindings and shell options, which test.sh
# does not cover.
#
# Usage:
#   scripts/shell-snapshot.sh > before.txt
#   # …make a change, chezmoi apply…
#   scripts/shell-snapshot.sh > after.txt
#   diff before.txt after.txt        # must be empty (see bench/tuning-routine.md)
set -euo pipefail

# A sentinel separates the greeting/MOTD (printed while .zshrc sources) from the
# dump, so the fingerprint is independent of that noise. Everything up to and
# including the marker is stripped below.
marker="@@SHELL-SNAPSHOT@@"

zsh -i -c '
    emulate -L zsh
    print -r -- "'"$marker"'"
    print -r -- "## aliases"
    for k in ${(ko)aliases};  print -r -- "$k=${aliases[$k]}"
    for k in ${(ko)galiases}; print -r -- "global $k=${galiases[$k]}"
    for k in ${(ko)saliases}; print -r -- "suffix $k=${saliases[$k]}"
    print -r -- "## functions"
    print -rl -- ${(ko)functions}
    print -r -- "## abbreviations"
    (( $+functions[abbr] )) && abbr list 2>/dev/null | sort
    print -r -- "## bindkeys"
    bindkey -L | sort
    print -r -- "## options"
    setopt | sort
' | awk -v m="$marker" 'p; $0==m {p=1}'
