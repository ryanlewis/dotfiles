#!/bin/bash

# Claude Code statusLine command
# Mirrors the user's Starship prompt configuration

# Read JSON input from stdin — single jq call extracts all fields
IFS=$'\t' read -r model_name current_dir used_pct worktree_name worktree_branch < <(
    jq -r '[
        .model.display_name,
        .workspace.current_dir,
        (.context_window.used_percentage // ""),
        (.worktree.name // ""),
        (.worktree.branch // "")
    ] | join("\t")' </dev/stdin
)

# Shorten model name: "Opus 4.6 (1M context)" → "Opus 4.6 (1M)"
model_name="${model_name/ context)/)}"

# Path truncation using bash builtins
truncate_path() {
    local p="$1"
    local dev_prefix="$HOME/dev/"
    if [[ "$p" == "$dev_prefix"* ]]; then
        # Under ~/dev → strip the prefix
        printf '%s' "${p#$dev_prefix}"
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
        printf '%s' "$p"
    fi
}

truncated_dir=$(truncate_path "$current_dir")

# Git information (branch + status), skipping optional locks
git_branch=""
git_status_str=""
git_worktree_label=""
if git -C "$current_dir" -c core.checkStat=minimal rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
    git_branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)

    # Detect linked worktree — single rev-parse call for both values
    read -r git_dir git_common_dir < <(
        git -C "$current_dir" --no-optional-locks rev-parse --git-dir --git-common-dir 2>/dev/null | tr '\n' ' '
    )
    if [[ -n "$git_dir" && -n "$git_common_dir" && "$git_dir" != "$git_common_dir" ]]; then
        if [[ -n "$worktree_name" ]]; then
            git_worktree_label="$worktree_name"
        else
            worktree_path=$(git -C "$current_dir" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
            git_worktree_label="${worktree_path##*/}"
        fi

        # Show the main project directory instead of the worktree path
        truncated_dir=$(truncate_path "${git_common_dir%/.git}")
    fi

    # Build compact status flags using bash pattern matching (no grep forks)
    status_flags=""
    git_status_output=$(git -C "$current_dir" --no-optional-locks status --porcelain 2>/dev/null)
    if [[ -n "$git_status_output" ]]; then
        [[ "$git_status_output" =~ ^[MARCDT] ]] && status_flags+="+"
        [[ "$git_status_output" =~ $'\n'.[MD] || "$git_status_output" =~ ^.[MD] ]] && status_flags+="!"
        [[ "$git_status_output" =~ ^\?\? || "$git_status_output" =~ $'\n'\?\? ]] && status_flags+="?"
        [[ "$git_status_output" =~ ^.D || "$git_status_output" =~ ^D || "$git_status_output" =~ $'\n'.D || "$git_status_output" =~ $'\n'D ]] && status_flags+="✘"
    fi

    # Ahead/behind upstream — parse with bash read instead of awk
    if read -r behind ahead < <(git -C "$current_dir" --no-optional-locks rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null); then
        (( ahead > 0 )) && status_flags+="⇡${ahead}"
        (( behind > 0 )) && status_flags+="⇣${behind}"
    fi

    [[ -n "$status_flags" ]] && git_status_str="[${status_flags}]"
fi

# Context window usage indicator
context_str=""
if [[ -n "$used_pct" ]]; then
    printf -v used_int "%.0f" "$used_pct"
    context_str="${used_int}%"
fi

# Build the status line with colours matching Starship theme
#   directory    → bold cyan    |  git branch  → bold purple
#   git worktree → bold yellow  |  git status  → bold red
#   model        → normal white |  context     → bold yellow

parts="\033[1;36m${truncated_dir}\033[0m"

if [[ -n "$git_branch" ]]; then
    parts+=" \033[1;35m ${git_branch}\033[0m"
    if [[ -n "$git_worktree_label" ]]; then
        if [[ "$git_worktree_label" == "$git_branch" || "$git_worktree_label" == "${git_branch//\//-}" ]]; then
            parts+=" \033[1;33m[wt]\033[0m"
        else
            parts+=" \033[1;33m[wt:${git_worktree_label}]\033[0m"
        fi
    fi
    [[ -n "$git_status_str" ]] && parts+=" \033[1;31m${git_status_str}\033[0m"
fi

parts+=" \033[2;37m|\033[0m"
parts+=" \033[0;37m${model_name}\033[0m"
[[ -n "$context_str" ]] && parts+=" \033[1;33mctx:${context_str}\033[0m"

printf '%b' "$parts"
