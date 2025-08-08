function dogpound
    cd ~/dev/dogpound
    
    # Check if tmux session exists
    if tmux has-session -t claude 2>/dev/null
        tmux attach -t claude
    else
        # Create new session with proper terminal settings
        tmux new-session -s claude -d
        tmux send-keys -t claude "claude -c" Enter
        tmux attach -t claude
    end
end
