#!/usr/bin/env bash
# PreToolUse guard for `git worktree remove --force`.
#
# Force-removing a worktree with uncommitted work discards it, so that should
# prompt. Two cases should not: throwaway worktrees agents build in their
# scratchpad (`D=<scratchpad>/x; git worktree add --detach $D origin/main; ...;
# git worktree remove --force $D`), and clean worktrees, e.g. a worker's
# worktree after its PR has merged.
#
# Decisions:
#   ask    - a forced remove whose target is neither inside a Claude scratch
#            dir (/private/tmp/claude-<uid>/ or /tmp/claude-<uid>/) nor an
#            existing worktree with an empty `git status --porcelain`
#   (none) - no forced remove, or every target is scratch or clean: falls
#            through to normal permission handling (auto mode still judges
#            the rest)
#
# Removing a locked worktree (-ff / --force --force) asks unless the target is
# scratch: the lock means someone meant to keep it.
#
# Targets may be literal paths or $VAR / ${VAR} set earlier in the same
# command (VAR=path or VAR=$(mktemp -d path)), resolved recursively. Relative
# targets resolve against the session cwd, updated by any `cd DIR` segment
# earlier in the same command.

set -f
uid=$(id -u)
SCRATCH_ROOTS="/private/tmp/claude-$uid/ /tmp/claude-$uid/"

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cmd" ] || exit 0
case "$cmd" in *"worktree remove"*) ;; *) exit 0 ;; esac

emit() { # $1 decision, $2 reason
  jq -cn --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
}

# Fail closed: any crash below prompts rather than falling through.
trap 'rc=$?; [ $rc -eq 0 ] || emit ask "worktree-force-guard could not parse the command"; exit 0' EXIT

unquote() { local v=$1; v=${v%\"}; v=${v#\"}; v=${v%\'}; v=${v#\'}; printf '%s' "$v"; }

# NAME=value assignments; a later assignment of the same name wins.
names=(); vals=()
while IFS= read -r a; do
  [ -n "$a" ] || continue
  name=${a%%=*}
  val=$(unquote "${a#*=}")
  case "$val" in
    '$(mktemp -d '*')') val=${val#'$(mktemp -d '}; val=${val%')'} ;;
    '$('*) val="" ;;  # other command substitutions can't be resolved
  esac
  names+=("$name"); vals+=("$val")
done < <(printf '%s' "$cmd" | grep -oE '(^|[[:space:];&|(])[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'"'"'[^'"'"']*'"'"'|\$\([^)]*\)|[^[:space:];&|]+)' \
  | sed -E 's/^[[:space:];&|(]//')

resolve() { # expand $VAR / ${VAR} from vars, a few rounds for nesting
  local p=$1 i j n v
  for i in 1 2 3 4; do
    for ((j=${#names[@]}-1; j>=0; j--)); do
      n=${names[j]}; v=${vals[j]}
      p=${p//\$\{$n\}/$v}
      p=${p//\$$n/$v}
    done
  done
  case "$p" in "~"|"~/"*) p="$HOME${p#\~}" ;; esac
  printf '%s' "$p"
}

unsafe_path() { case "$1" in *'$'*|*..*|*'`'*) return 0 ;; esac; return 1; }

is_scratch() {
  local p=$1 r
  unsafe_path "$p" && return 1
  for r in $SCRATCH_ROOTS; do
    case "$p" in "$r"?*) return 0 ;; esac
  done
  return 1
}

is_clean_worktree() { # existing absolute path, a worktree with nothing to lose
  local p=$1 out
  case "$p" in /*) ;; *) return 1 ;; esac
  unsafe_path "$p" && return 1
  [ -d "$p" ] || return 1
  [ "$(git -C "$p" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || return 1
  out=$(git -C "$p" status --porcelain 2>/dev/null) || return 1
  [ -z "$out" ]
}

forced=0
IFS=$'\n'
for seg in $(printf '%s' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g'); do
  if [[ $seg =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]]+)[[:space:]]*$ ]]; then
    d=$(resolve "$(unquote "${BASH_REMATCH[1]}")")
    case "$d" in /*) cwd=$d ;; *) [ -n "$cwd" ] && cwd="$cwd/$d" ;; esac
    continue
  fi
  case "$seg" in *"worktree remove"*) ;; *) continue ;; esac
  rest=${seg#*worktree remove}
  case " $rest " in *" -f "*|*" --force "*|*" -ff "*) ;; *) continue ;; esac
  forced=1
  locked=0
  case " $rest " in *" -ff "*|*" -f "*" -f "*|*" --force "*" --force "*|*" -f "*" --force "*|*" --force "*" -f "*) locked=1 ;; esac
  unset IFS
  for w in $rest; do
    w=$(unquote "${w%)}")
    w=$(unquote "$w")
    case "$w" in -*|""|*[\<\>]*) continue ;; esac
    p=$(resolve "$w")
    is_scratch "$p" && continue
    case "$p" in /*) abs=$p ;; *) abs=${cwd:+$cwd/$p} ;; esac
    if [ "$locked" = 0 ] && [ -n "$abs" ] && is_clean_worktree "$abs"; then
      continue
    fi
    if [ "$locked" = 1 ]; then
      emit ask "git worktree remove on locked worktree $w (-ff), which is not a Claude scratch dir"
    else
      emit ask "git worktree remove --force on $w, which is neither a Claude scratch dir nor a clean worktree (uncommitted work would be lost)"
    fi
    exit 0
  done
  IFS=$'\n'
done
unset IFS

exit 0
