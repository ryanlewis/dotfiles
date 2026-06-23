#!/usr/bin/env bash
# Profile interactive zsh startup with zsh/zprof, attributing time to each
# function and sourced segment (compinit, plugin sourcing, each cached
# tool-init, conf.d/* and functions/* loading).
#
#   scripts/profile-startup.sh          # warm: profile against populated caches
#   scripts/profile-startup.sh --cold   # bust startup caches first, then profile
#
# Works by pointing ZDOTDIR at a throwaway dir whose .zshrc loads zprof, sources
# the real ~/.zshrc, then prints the report — so nothing in the tracked config
# has to be touched. zprof's table is sorted by self-time descending.
set -euo pipefail

cold=0
case ${1:-} in
    --cold)    cold=1 ;;
    "")        ;;
    -h|--help) grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
esac

ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if (( cold )); then
    rm -rf "$ZSH_CACHE/init" "$ZSH_CACHE"/zcompdump*
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# ZDOTDIR overrides where zsh reads .zshenv/.zshrc, so re-source the real ones.
cat > "$tmp/.zshenv" <<'EOF'
[[ -r ~/.zshenv ]] && source ~/.zshenv
EOF
cat > "$tmp/.zshrc" <<'EOF'
zmodload zsh/zprof
[[ -r ~/.zshrc ]] && source ~/.zshrc
zprof
EOF

ZDOTDIR="$tmp" zsh -i -c exit
