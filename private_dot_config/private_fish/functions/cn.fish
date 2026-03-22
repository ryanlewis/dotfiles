function cn --description "Open Claude in notes vault with split pane"
    set -l prompt (string join ' ' $argv)
    set -l win_name "notes"

    # Generate a slug from the prompt using Haiku
    if test -n "$prompt"
        set -l slug (echo "Generate a short 2-3 word kebab-case slug for this task. Output ONLY the slug, nothing else: $prompt" | \
            claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt='' 2>/dev/null | string trim)
        if test -n "$slug"
            set win_name "notes:$slug"
        end
    end

    if set -q TMUX
        # Inside tmux: new window
        tmux new-window -n "$win_name" -c ~/dev/notes
    else
        # Outside tmux: new session
        tmux new-session -d -s "$win_name" -c ~/dev/notes
        tmux switch-client -t "$win_name" 2>/dev/null || tmux attach -t "$win_name"
    end

    if test -n "$prompt"
        tmux send-keys "claude '$prompt'" Enter
    else
        tmux send-keys "claude" Enter
    end
end
