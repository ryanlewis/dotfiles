# Attach to tmux session or create new one
ta() {
    if (( $# == 0 )); then
        # No arguments — list sessions
        tmux list-sessions 2>/dev/null || echo "No tmux sessions. Start with: tmux new -s <name>"
    else
        # Attach to existing session or create new one with given name
        tmux attach -t "$1" 2>/dev/null || tmux new -s "$1"
    fi
}
