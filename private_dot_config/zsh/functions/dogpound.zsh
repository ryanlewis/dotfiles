# Open the dogpound project in a tmux session running Claude
dogpound() {
    cd ~/dev/dogpound || return

    if tmux has-session -t claude 2>/dev/null; then
        tmux attach -t claude
    else
        tmux new-session -s claude -d
        tmux send-keys -t claude "claude -c" Enter
        tmux attach -t claude
    fi
}
