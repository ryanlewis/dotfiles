# Tmux attach/create helper function
function ta --description "Attach to tmux session or create new one"
    if test (count $argv) -eq 0
        # No arguments - list sessions
        tmux list-sessions 2>/dev/null || echo "No tmux sessions. Start with: tmux new -s <name>"
    else
        # Attach to existing session or create new one with given name
        tmux attach -t $argv[1] 2>/dev/null || tmux new -s $argv[1]
    end
end