#!/usr/bin/env bash
# PreToolUse guard for `gh pr merge`.
#
# Policy (pr-write-policy): personal repos merge on green without asking,
# work repos never merge unattended. Auto-allows a merge when the target repo
# is owned by an allowed GitHub user and the command contains nothing else of
# consequence; otherwise forces a prompt.
#
# Decisions:
#   allow  - every command segment is cd / gh pr view|checks|merge, no --admin,
#            and the resolved repo owner is in ALLOWED_OWNERS
#   ask    - a clean merge command whose owner is not allowed, or uses --admin
#   (none) - anything else falls through to normal permission handling
#
# Repo resolution: -R/--repo flag if given, else the git remote of the
# directory the merge runs in (last `cd` in the command, else the hook cwd).
# Refuses to guess when the directory has more than one remote (forks).

set -uf  # -f: no glob expansion of command segments in the loop below
ALLOWED_OWNERS="ryanlewis"

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

[ -n "$cmd" ] || exit 0
case "$cmd" in *"gh pr merge"*) ;; *) exit 0 ;; esac

emit() { # $1 decision, $2 reason
  jq -cn --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
}

dir="$cwd"
repo=""
admin=0
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
    gh\ pr\ view*|gh\ pr\ checks*) ;;
    gh\ pr\ merge*)
      case " $seg " in *" --admin "*) admin=1 ;; esac
      r=$(printf '%s' "$seg" | grep -oE -- '(-R|--repo)[= ]+[^ ]+' | head -1 | sed -E 's/^(-R|--repo)[= ]+//')
      [ -n "$r" ] && repo="$r"
      ;;
    *) exit 0 ;;
  esac
done
unset IFS

if [ -z "$repo" ]; then
  [ -d "$dir" ] || exit 0
  remotes=$(git -C "$dir" remote 2>/dev/null)
  [ "$(printf '%s\n' "$remotes" | grep -c .)" -eq 1 ] || { emit ask "gh pr merge: repo has no single remote, cannot resolve owner"; exit 0; }
  url=$(git -C "$dir" remote get-url "$remotes" 2>/dev/null) || exit 0
  repo=$(printf '%s' "$url" | sed -E 's#^(git@|ssh://git@|https://)github\.com[:/]##; s#\.git$##')
fi

owner=${repo%%/*}
[ -n "$owner" ] && [ "$owner" != "$repo" ] || exit 0

if [ "$admin" -eq 1 ]; then
  emit ask "gh pr merge --admin bypasses branch protection"
  exit 0
fi

for a in $ALLOWED_OWNERS; do
  if [ "$owner" = "$a" ]; then
    emit allow "gh pr merge in $repo (owner $owner is allowed)"
    exit 0
  fi
done

emit ask "gh pr merge in $repo: owner $owner is not in the personal allowlist"
