#!/usr/bin/env bash
# PreToolUse guard for `git push --force-with-lease`.
#
# Lets hc-lead / subagent-lead workers rebase their own PR branch in personal
# repos. Auto-allows a push only when all of these hold:
#   - every command segment is `cd ...` or the one git push
#   - the push uses --force-with-lease and nothing stronger (--force, -f, +ref,
#     --mirror, --all, --delete, --tags)
#   - the remote is origin (or omitted) and there is at most one refspec
#   - the target branch is fix/*, test/* or refactor/*
#   - origin's owner is in ALLOWED_OWNERS
# Anything else falls through to normal permission handling (no output).

set -uf
ALLOWED_OWNERS="ryanlewis"
BRANCH_RE='^(fix|test|refactor)/'

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

[ -n "$cmd" ] || exit 0
case "$cmd" in *"--force-with-lease"*) ;; *) exit 0 ;; esac

emit() { # $1 decision, $2 reason
  jq -cn --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
}

# Command substitution or redirection could hide anything: do not judge it.
case "$cmd" in *'$('*|*'`'*|*'>'*|*'<'*) exit 0 ;; esac

dir="$cwd"
push=""
IFS=$'\n'
for seg in $(printf '%s' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g'); do
  seg=$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  [ -n "$seg" ] || continue
  case "$seg" in
    cd\ *)
      d=${seg#cd }
      d=${d%\"}; d=${d#\"}; d=${d%\'}; d=${d#\'}
      case "$d" in "~"|"~/"*) d="$HOME${d#\~}" ;; esac
      case "$d" in /*) dir="$d" ;; *) dir="$cwd/$d" ;; esac
      ;;
    git\ *push\ *)
      [ -z "$push" ] || exit 0  # more than one push: not ours to judge
      push="$seg"
      ;;
    *) exit 0 ;;
  esac
done
unset IFS
[ -n "$push" ] || exit 0

# Split the push into words (no quoting expected in a branch push).
read -r -a words <<<"$push"
[ "${words[0]}" = git ] || exit 0
i=1
# git -C <path> push ...
while [ "$i" -lt "${#words[@]}" ] && [ "${words[$i]}" != push ]; do
  case "${words[$i]}" in
    -C)
      i=$((i + 1))
      d=${words[$i]:-}
      case "$d" in "~"|"~/"*) d="$HOME${d#\~}" ;; esac
      case "$d" in /*) dir="$d" ;; *) dir="$dir/$d" ;; esac
      ;;
    *) exit 0 ;;  # any other global option: fall through
  esac
  i=$((i + 1))
done
[ "${words[$i]:-}" = push ] || exit 0
i=$((i + 1))

lease=0
pos=()
for w in "${words[@]:$i}"; do
  case "$w" in
    --force-with-lease|--force-with-lease=*) lease=1 ;;
    --force-if-includes|-u|--set-upstream|--no-verify|-q|--quiet|-v|--verbose) ;;
    -*) exit 0 ;;  # --force, -f, --mirror, --all, --delete, --tags, ...
    +*) exit 0 ;;  # forced refspec
    *) pos+=("$w") ;;
  esac
done
[ "$lease" -eq 1 ] || exit 0
[ "${#pos[@]}" -le 2 ] || exit 0

remote=${pos[0]:-origin}
[ "$remote" = origin ] || exit 0

[ -d "$dir" ] || exit 0
if [ "${#pos[@]}" -eq 2 ]; then
  ref=${pos[1]}
  ref=${ref#*:}             # src:dst -> dst
  ref=${ref#refs/heads/}
  [ "$ref" != HEAD ] || ref=$(git -C "$dir" branch --show-current 2>/dev/null)
else
  ref=$(git -C "$dir" branch --show-current 2>/dev/null)
fi
[ -n "$ref" ] || exit 0
printf '%s' "$ref" | grep -qE "$BRANCH_RE" || exit 0

url=$(git -C "$dir" remote get-url origin 2>/dev/null) || exit 0
repo=$(printf '%s' "$url" | sed -E 's#^(git@|ssh://git@|https://)github\.com[:/]##; s#\.git$##')
owner=${repo%%/*}
[ -n "$owner" ] && [ "$owner" != "$repo" ] || exit 0

for a in $ALLOWED_OWNERS; do
  if [ "$owner" = "$a" ]; then
    emit allow "force-with-lease push of $ref in $repo (personal worker branch)"
    exit 0
  fi
done
exit 0
