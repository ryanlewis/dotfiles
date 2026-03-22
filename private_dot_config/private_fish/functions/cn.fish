function cn --description "Open Claude in notes vault"
    # Consume stdin early if piped, save to temp file
    set -l prompt_file ""
    if not isatty stdin
        set prompt_file (mktemp /tmp/cn-prompt.XXXXXX)
        cat > "$prompt_file"
    end

    # Build prompt from file and/or args
    set -l prompt ""
    if test -n "$prompt_file"
        set prompt (cat "$prompt_file")
    end
    if test (count $argv) -gt 0
        if test -n "$prompt"
            set prompt "$prompt\n"(string join ' ' $argv)
        else
            set prompt (string join ' ' $argv)
        end
    end

    # Window name: slug or "notes"
    set -l win_name "notes"
    if test -n "$prompt"
        # Truncate and sanitise for slug generation
        set -l slug_input (string sub -l 200 "$prompt" | string replace -ra '[^a-zA-Z0-9 ]' ' ' | string trim)
        set -l slug
        if command -q aichat
            set slug (aichat "Output ONLY a 2-3 word kebab-case slug for: $slug_input" 2>/dev/null | string trim)
        else if command -q claude
            set slug (claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt='' "Output ONLY a 2-3 word kebab-case slug for: $slug_input" 2>/dev/null | string trim)
        end
        if test -n "$slug"
            set win_name "$slug"
        end
    end

    # Build the claude command
    set -l claude_cmd "claude"
    if test -n "$prompt_file"
        set claude_cmd "claude (cat $prompt_file); rm -f $prompt_file"
    else if test -n "$prompt"
        set claude_cmd "claude '$prompt'"
    end

    # Can't tmux attach when stdin was a pipe
    set -l can_attach true
    if test -n "$prompt_file"
        set can_attach false
    end

    if set -q TMUX
        tmux new-window -n "$win_name" -c ~/dev/notes
        tmux send-keys "$claude_cmd" Enter
    else if tmux has-session -t notes 2>/dev/null
        tmux new-window -a -t notes -n "$win_name" -c ~/dev/notes
        tmux send-keys -t "notes:$win_name" "$claude_cmd" Enter
        if test "$can_attach" = true
            tmux attach -t notes
        else
            echo "Claude launched in notes/$win_name"
            echo "Attach: tmux attach -t notes"
        end
    else
        tmux new-session -d -s notes -n "$win_name" -c ~/dev/notes
        tmux send-keys -t "notes:$win_name" "$claude_cmd" Enter
        if test "$can_attach" = true
            tmux attach -t notes
        else
            echo "Claude launched in notes/$win_name"
            echo "Attach: tmux attach -t notes"
        end
    end
end
