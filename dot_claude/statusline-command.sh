#!/bin/bash

# Claude Code statusLine command
# Mirrors the user's Starship prompt configuration

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# Shorten model name: strip " context" from parentheticals, e.g.
# "Opus 4.6 (1M context)" → "Opus 4.6 (1M)"
model_name=$(echo "$model_name" | sed 's/ context)/)/g')

# Replace $HOME with ~ before truncating so the prefix survives truncation
display_dir=$(echo "$current_dir" | sed "s|^$HOME|~|")
# Truncate to last 3 path components (Starship truncation_length = 3)
truncated_dir=$(echo "$display_dir" | awk -F'/' '{
    n = NF
    if (n <= 3) { print $0 }
    else { print "…/" $(n-2) "/" $(n-1) "/" $n }
}')

# Git information (branch + status), skipping optional locks
git_branch=""
git_status_str=""
git_worktree_label=""
if git -C "$current_dir" -c core.checkStat=minimal rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
    git_branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)

    # Detect if we are inside a linked worktree (not the main worktree)
    git_dir=$(git -C "$current_dir" --no-optional-locks rev-parse --git-dir 2>/dev/null)
    git_common_dir=$(git -C "$current_dir" --no-optional-locks rev-parse --git-common-dir 2>/dev/null)
    if [[ -n "$git_dir" && -n "$git_common_dir" && "$git_dir" != "$git_common_dir" ]]; then
        # We are in a linked worktree — derive a label to display
        if [[ -n "$worktree_name" ]]; then
            # Prefer the name from Claude's JSON input
            git_worktree_label="$worktree_name"
        else
            # Fall back to the last path component of the worktree directory
            worktree_path=$(git -C "$current_dir" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
            git_worktree_label=$(basename "$worktree_path")
        fi
    fi

    # Build a compact status string (matching Starship git_status format)
    status_flags=""
    git_status_output=$(git -C "$current_dir" --no-optional-locks status --porcelain 2>/dev/null)
    if [[ -n "$git_status_output" ]]; then
        # Staged changes
        if echo "$git_status_output" | grep -q '^[MARCDT]'; then
            status_flags="${status_flags}+"
        fi
        # Unstaged modifications
        if echo "$git_status_output" | grep -q '^.[MD]'; then
            status_flags="${status_flags}!"
        fi
        # Untracked files
        if echo "$git_status_output" | grep -q '^??'; then
            status_flags="${status_flags}?"
        fi
        # Deleted files
        if echo "$git_status_output" | grep -q '^.D\|^D'; then
            status_flags="${status_flags}✘"
        fi
    fi

    # Ahead/behind upstream
    ahead_behind=$(git -C "$current_dir" --no-optional-locks rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
    if [[ -n "$ahead_behind" ]]; then
        behind=$(echo "$ahead_behind" | awk '{print $1}')
        ahead=$(echo "$ahead_behind" | awk '{print $2}')
        [[ "$ahead" -gt 0 ]] && status_flags="${status_flags}⇡${ahead}"
        [[ "$behind" -gt 0 ]] && status_flags="${status_flags}⇣${behind}"
    fi

    [[ -n "$status_flags" ]] && git_status_str="[$status_flags]"
fi

# Context window usage indicator
context_str=""
if [[ -n "$used_pct" ]]; then
    # Round to nearest integer
    used_int=$(printf "%.0f" "$used_pct")
    context_str="${used_int}%"
fi

# Build the status line with colours matching Starship theme:
#   directory      → bold cyan    (\033[1;36m)
#   git branch     → bold purple  (\033[1;35m)
#   git worktree   → bold yellow  (\033[1;33m)
#   git status     → bold red     (\033[1;31m)
#   model          → normal white (\033[0;37m)
#   context        → bold yellow  (\033[1;33m)

parts=""

# Directory (bold cyan)
parts+="$(printf '\033[1;36m%s\033[0m' "$truncated_dir")"

# Git branch + optional worktree label + status
if [[ -n "$git_branch" ]]; then
    parts+=" $(printf '\033[1;35m %s\033[0m' "$git_branch")"
    if [[ -n "$git_worktree_label" ]]; then
        parts+=" $(printf '\033[1;33m[wt:%s]\033[0m' "$git_worktree_label")"
    fi
    if [[ -n "$git_status_str" ]]; then
        parts+=" $(printf '\033[1;31m%s\033[0m' "$git_status_str")"
    fi
fi

# Separator
parts+=" $(printf '\033[2;37m|\033[0m')"

# Model (normal white)
parts+=" $(printf '\033[0;37m%s\033[0m' "$model_name")"

# Context window usage (bold yellow, only when available)
if [[ -n "$context_str" ]]; then
    parts+=" $(printf '\033[1;33mctx:%s\033[0m' "$context_str")"
fi

printf '%s' "$parts"