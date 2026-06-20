# Open Claude in notes vault
cn() {
    # Consume stdin early if piped, save to temp file.
    local prompt_file=""
    if [[ ! -t 0 ]]; then
        prompt_file=$(mktemp /tmp/cn-prompt.XXXXXX)
        cat > "$prompt_file"
    fi

    # Build prompt from file and/or args.
    local prompt=""
    [[ -n $prompt_file ]] && prompt=$(cat "$prompt_file")
    if (( $# > 0 )); then
        if [[ -n $prompt ]]; then
            prompt="$prompt"$'\n'"$*"
        else
            prompt="$*"
        fi
    fi

    # Window name: slug or "notes".
    local win_name="notes" slug
    if [[ -n $prompt ]]; then
        slug=$(echo "$prompt" | slugify 2>/dev/null)
        [[ -n $slug ]] && win_name="$slug"
    fi

    # Build the claude command (POSIX command substitution; runs in the zsh
    # window spawned by tmux).
    local claude_cmd="claude"
    local can_attach=true
    if [[ -n $prompt_file ]]; then
        claude_cmd="claude \"\$(cat $prompt_file)\"; rm -f $prompt_file"
        # Can't tmux attach when stdin was a pipe.
        can_attach=false
    elif [[ -n $prompt ]]; then
        claude_cmd="claude '$prompt'"
    fi

    if [[ -n $TMUX ]]; then
        tmux new-window -n "$win_name" -c ~/dev/notes
        tmux send-keys "$claude_cmd" Enter
    elif tmux has-session -t notes 2>/dev/null; then
        tmux new-window -a -t notes -n "$win_name" -c ~/dev/notes
        tmux send-keys -t "notes:$win_name" "$claude_cmd" Enter
        if [[ $can_attach == true ]]; then
            tmux attach -t notes
        else
            echo "Claude launched in notes/$win_name"
            echo "Attach: tmux attach -t notes"
        fi
    else
        tmux new-session -d -s notes -n "$win_name" -c ~/dev/notes
        tmux send-keys -t "notes:$win_name" "$claude_cmd" Enter
        if [[ $can_attach == true ]]; then
            tmux attach -t notes
        else
            echo "Claude launched in notes/$win_name"
            echo "Attach: tmux attach -t notes"
        fi
    fi
}
