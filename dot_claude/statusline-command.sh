#!/bin/bash

# Claude Code statusLine command
# Mirrors the user's Starship prompt configuration

# Read JSON input from stdin — single jq call emits one field per line.
# Line-based (not tab-joined) so empty optional fields aren't collapsed by read.
{
    IFS= read -r model_name
    IFS= read -r current_dir
    IFS= read -r used_pct
    IFS= read -r worktree_name
    IFS= read -r git_worktree
    IFS= read -r effort_level
    IFS= read -r fast_mode
    IFS= read -r week_pct
    IFS= read -r five_pct
    IFS= read -r spend_pct
    IFS= read -r session_cost
    IFS= read -r pr_number
    IFS= read -r pr_state
    IFS= read -r cache_observed
    IFS= read -r cache_expires
    IFS= read -r now
} < <(
    jq -r '
        .model.display_name,
        .workspace.current_dir,
        (.context_window.used_percentage // ""),
        (.worktree.name // ""),
        (.workspace.git_worktree // ""),
        (.effort.level // ""),
        (.fast_mode // false),
        (.rate_limits.seven_day.used_percentage // ""),
        (.rate_limits.five_hour.used_percentage // ""),
        (.rate_limits.spend_limit.used_percentage // ""),
        (.cost.total_cost_usd // ""),
        (.pr.number // ""),
        (.pr.review_state // ""),
        (.prompt_cache.caching_observed // false),
        (.prompt_cache.expires_at // ""),
        (now | floor)
    ' </dev/stdin
)

# Shorten model name: "Opus 4.6 (1M context)" → "Opus 4.6 (1M)"
model_name="${model_name/ context)/)}"

# Path truncation using bash builtins. Sets REPLY rather than printing, so
# callers don't pay for a subshell.
truncate_path() {
    local p="$1"
    local dev_prefix="$HOME/dev/"
    if [[ "$p" == "$dev_prefix"* ]]; then
        # Under ~/dev → strip the prefix
        REPLY="${p#$dev_prefix}"
    else
        # Not under ~/dev — replace $HOME with ~ and truncate
        p="${p/#$HOME/~}"
        local stripped="${p//[!\/]/}"
        local depth=${#stripped}
        if (( depth >= 3 )); then
            local tail="${p##*/}"; p="${p%/*}"
            local mid="${p##*/}"; p="${p%/*}"
            local head="${p##*/}"
            p="…/${head}/${mid}/${tail}"
        fi
        REPLY="$p"
    fi
}

truncate_path "$current_dir"
truncated_dir="$REPLY"

# Git information. One `status --porcelain=v2 --branch` call gives the branch,
# ahead/behind and file states; it fails outside a repo, leaving all empty.
git_branch=""
git_status_str=""
git_worktree_label=""
staged="" unstaged="" untracked="" deleted="" conflicted="" ahead=0 behind=0
while IFS= read -r line; do
    case "$line" in
        "# branch.head "*) git_branch="${line#\# branch.head }" ;;
        "# branch.ab "*)
            read -r _ _ ahead behind <<< "$line"
            ahead="${ahead#+}" behind="${behind#-}" ;;
        "#"*) ;;
        "? "*) untracked="?" ;;
        "u "*) conflicted="=" ;;
        [12]" "*)
            xy="${line:2:2}"
            [[ "${xy:0:1}" != "." ]] && staged="+"
            [[ "${xy:1:1}" == [MD] ]] && unstaged="!"
            [[ "$xy" == *D* ]] && deleted="✘" ;;
    esac
done < <(git -C "$current_dir" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)

# Detached HEAD reports "(detached)"; show nothing, as before
[[ "$git_branch" == "(detached)" ]] && git_branch=""

if [[ -n "$git_branch" ]]; then
    status_flags="${conflicted}${staged}${unstaged}${untracked}${deleted}"
    (( ahead > 0 )) && status_flags+="⇡${ahead}"
    (( behind > 0 )) && status_flags+="⇣${behind}"
    [[ -n "$status_flags" ]] && git_status_str="[${status_flags}]"

    # Linked worktree — Claude Code names it in the payload, so git is only
    # asked for the main checkout's path when we're actually in one
    if [[ -n "$git_worktree" ]]; then
        git_worktree_label="${worktree_name:-$git_worktree}"
        git_common_dir=$(git -C "$current_dir" --no-optional-locks rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
        # Show the main project directory instead of the worktree path
        if [[ -n "$git_common_dir" ]]; then
            truncate_path "${git_common_dir%/.git}"
            truncated_dir="$REPLY"
        fi
    fi
fi

# Context window usage indicator
context_str=""
if [[ -n "$used_pct" ]]; then
    printf -v used_int "%.0f" "$used_pct"
    context_str="${used_int}%"
fi

# Build the status line with colours matching Starship theme. Rendered over two
# rows (Claude Code shows one terminal line per output line):
#   line 1 — directory (bold cyan), branch (bold purple), worktree (bold
#            yellow), git status (bold red), open PR
#   line 2 — model (normal white), fast mode, effort, context, usage limits,
#            session cost, prompt cache

line1="\033[1;36m ${truncated_dir}\033[0m"

if [[ -n "$git_branch" ]]; then
    line1+="  \033[1;35m ${git_branch}\033[0m"
    if [[ -n "$git_worktree_label" ]]; then
        if [[ "$git_worktree_label" == "$git_branch" || "$git_worktree_label" == "${git_branch//\//-}" ]]; then
            line1+="  \033[1;33m󰙅\033[0m"
        else
            line1+="  \033[1;33m󰙅 ${git_worktree_label}\033[0m"
        fi
    fi
    [[ -n "$git_status_str" ]] && line1+="  \033[1;31m${git_status_str}\033[0m"
fi

# Open PR (or GitLab MR) for the branch, coloured by review state. Absent until
# Claude Code finds one, and once it merges or closes.
if [[ -n "$pr_number" ]]; then
    case "$pr_state" in
        approved)          pr_colour="1;32" ;; # green
        changes_requested) pr_colour="1;31" ;; # red
        pending)           pr_colour="1;33" ;; # yellow
        draft)             pr_colour="2;37" ;; # dim
        *)                 pr_colour="1;34" ;; # blue — state unknown
    esac
    line1+="  \033[${pr_colour}m #${pr_number}\033[0m"
fi

line2="\033[0;37m󰚩 ${model_name}\033[0m"

# Fast mode (/fast toggle) — bolt indicator next to the model
[[ "$fast_mode" == "true" ]] && line2+="  \033[1;33m󱐋\033[0m"

# Model effort (reasoning level) — only present when the model supports it
if [[ -n "$effort_level" ]]; then
    # Note: /effort ultracode reports as "xhigh" here — there is no "ultra"
    # value in the payload, so the two are indistinguishable in the statusline.
    case "$effort_level" in
        low)    eff_colour="1;32"       ;; # green
        medium) eff_colour="1;37"       ;; # white
        high)   eff_colour="1;33"       ;; # yellow
        xhigh)  eff_colour="1;38;5;208" ;; # orange
        max)    eff_colour="1;31"       ;; # red
        *)      eff_colour="0;37"       ;; # fallback
    esac
    line2+="  \033[${eff_colour}m󰧑 ${effort_level}\033[0m"
fi

if [[ -n "$context_str" ]]; then
    if (( used_int < 10 )); then
        ctx_colour="1;32"        # green
    elif (( used_int < 25 )); then
        ctx_colour="1;33"        # yellow
    elif (( used_int < 50 )); then
        ctx_colour="1;38;5;208"  # orange
    else
        ctx_colour="1;31"        # red
    fi
    line2+="  \033[${ctx_colour}m󰍛 ${context_str}\033[0m"
fi

# Usage limits. Which windows arrive tells us the plan, so no config is needed:
#   five_hour/seven_day — claude.ai Pro/Max subscription (home)
#   spend_limit         — enterprise behind a Claude apps gateway (work)
#   none                — enterprise/API with no limits exposed
# All are absent before the first API response of a session, and each window
# is dropped once its reset time passes.

# limit_segment <icon> <pct> — appends a pill to line2
limit_segment() {
    local pct colour
    printf -v pct "%.0f" "$2"
    if   (( pct < 50 )); then colour="1;32"        # green
    elif (( pct < 75 )); then colour="1;33"        # yellow
    elif (( pct < 90 )); then colour="1;38;5;208"  # orange
    else                      colour="1;31"        # red
    fi
    line2+="  \033[${colour}m$1 ${pct}%\033[0m"
}

[[ -n "$five_pct" ]]  && limit_segment "󰔟" "$five_pct"
[[ -n "$week_pct" ]]  && limit_segment "" "$week_pct"
[[ -n "$spend_pct" ]] && limit_segment "󰄔" "$spend_pct"

# Session cost — client-side list-price estimate, same figure as /usage; resets
# on /clear.
if [[ -n "$session_cost" ]]; then
    printf -v cost_fmt '%.2f' "$session_cost"
    line2+="  \033[2;37m󰇁 ${cost_fmt}\033[0m"
fi

# Prompt cache — minutes until the cached prefix goes cold. Judged against the
# clock rather than .warm, which goes stale while the session is idle; needs
# refreshInterval in settings.json to tick down between events.
if [[ "$cache_observed" == "true" ]]; then
    if [[ -n "$cache_expires" ]] && (( ${cache_expires%.*} > now )); then
        cache_min=$(( (${cache_expires%.*} - now + 59) / 60 ))
        (( cache_min <= 5 )) && cache_colour="1;33" || cache_colour="0;36"
        line2+="  \033[${cache_colour}m󰆼 ${cache_min}m\033[0m"
    else
        line2+="  \033[2;37m󰆼 cold\033[0m"
    fi
fi

printf '%b' "${line1}\n${line2}"
