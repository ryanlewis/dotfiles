#!/usr/bin/env bash
# Benchmark interactive zsh startup latency (cold + warm) with hyperfine.
#
#   warm  — reuse the populated startup caches (_evalcache init dir +
#           compinit's zcompdump). This is the day-to-day reality.
#   cold  — bust those caches before every run, exercising the full rebuild
#           path (each `tool init` re-forks, compinit re-dumps).
#
# Emits hyperfine's native summary plus, when jq is available, a compact
# warm/cold table. With --json it writes a combined machine-readable result
# (the shape the tuning routine and any regression gate consume).
#
# hyperfine is a benchmarking dev-dependency, NOT a managed dotfiles tool, so
# this script bootstraps it on demand (PATH first, then a transient `mise x`)
# rather than expecting it to be installed.
#
# Usage:
#   scripts/bench-startup.sh [--json FILE] [--runs N] [--warmup N]
set -euo pipefail

json_out=""
runs=""
warmup=3

usage() { grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)    json_out=${2:?--json needs a path}; shift 2 ;;
        --json=*)  json_out=${1#*=}; shift ;;
        --runs)    runs=${2:?--runs needs a count};   shift 2 ;;
        --runs=*)  runs=${1#*=}; shift ;;
        --warmup)  warmup=${2:?--warmup needs a count}; shift 2 ;;
        --warmup=*) warmup=${1#*=}; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
    esac
done

# ── Resolve hyperfine (own it as a dependency; never assume it's installed) ──
if command -v hyperfine >/dev/null 2>&1; then
    HF=(hyperfine)
elif command -v mise >/dev/null 2>&1; then
    echo "hyperfine not on PATH — bootstrapping a transient copy via mise…" >&2
    HF=(mise x aqua:sharkdp/hyperfine -- hyperfine)
else
    echo "error: hyperfine is required and could not be bootstrapped." >&2
    echo "  install it:  brew install hyperfine" >&2
    echo "  or install mise so this script can fetch it on demand." >&2
    exit 1
fi

if [[ -n $json_out ]] && ! command -v jq >/dev/null 2>&1; then
    echo "error: --json needs jq to merge results, but jq is not on PATH." >&2
    exit 1
fi

# ── Startup caches (mirror the paths dot_zshrc.tmpl uses) ──
ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
# Quote the dir but leave the zcompdump* glob to expand in hyperfine's shell.
cold_prepare="rm -rf \"$ZSH_CACHE/init\" \"$ZSH_CACHE\"/zcompdump*"

target='zsh -i -c exit'

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

run_args=(-N --warmup "$warmup" --time-unit millisecond)
if [[ -n $runs ]]; then
    run_args+=(--runs "$runs")
else
    run_args+=(--min-runs 20)
fi

# Warm: make sure the caches are populated, then time with no cache-busting.
zsh -i -c exit >/dev/null 2>&1 || true
echo "▶ warm (caches populated)" >&2
"${HF[@]}" "${run_args[@]}" \
    --command-name warm \
    --export-json "$tmp/warm.json" \
    "$target" >&2

# Cold: bust the caches before every run.
echo "▶ cold (caches busted each run)" >&2
"${HF[@]}" "${run_args[@]}" \
    --prepare "$cold_prepare" \
    --command-name cold \
    --export-json "$tmp/cold.json" \
    "$target" >&2

# The final cold run repopulates the caches, but be explicit so we always leave
# the user's shell in the warm state we found it.
zsh -i -c exit >/dev/null 2>&1 || true

# ── Merge + summarise (jq only) ──
command -v jq >/dev/null 2>&1 || exit 0

hf_version="$("${HF[@]}" --version 2>/dev/null | awk '{print $NF}')"
zsh_version="$(zsh -c 'echo $ZSH_VERSION')"

merged="$(jq -n \
    --arg host "$(hostname)" \
    --arg os   "$(uname -s)" \
    --arg arch "$(uname -m)" \
    --arg ts   "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg zsh  "$zsh_version" \
    --arg hf   "$hf_version" \
    --slurpfile warm "$tmp/warm.json" \
    --slurpfile cold "$tmp/cold.json" \
    '{
        timestamp: $ts, host: $host, os: $os, arch: $arch,
        zsh_version: $zsh, hyperfine_version: $hf,
        command: "zsh -i -c exit",
        results: { warm: $warm[0].results[0], cold: $cold[0].results[0] }
    }')"

if [[ -n $json_out ]]; then
    mkdir -p "$(dirname "$json_out")"
    printf '%s\n' "$merged" > "$json_out"
    echo "wrote $json_out" >&2
fi

printf '%s\n' "$merged" | jq -r '
    def ms(x): (x*1000*10|round)/10;
    "",
    "  warm: \(ms(.results.warm.mean)) ms ± \(ms(.results.warm.stddev)) ms",
    "  cold: \(ms(.results.cold.mean)) ms ± \(ms(.results.cold.stddev)) ms",
    "  Δ cold−warm: \(ms(.results.cold.mean - .results.warm.mean)) ms"
' >&2
