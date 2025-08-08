# Custom greeting with system information
function fish_greeting
    set_color cyan
    echo "Welcome to "(hostname)" • "(lsb_release -ds 2>/dev/null || echo "Linux")" • "(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
    set_color yellow
    echo "Uptime: "(uptime -p 2>/dev/null || uptime)" • Load: "(uptime | awk -F'load average:' '{print $2}')

    # Show tmux sessions only if server is running
    if command -v tmux >/dev/null 2>&1; and tmux list-sessions >/dev/null 2>&1
        set_color magenta
        echo ""
        echo "Tmux sessions: (attach with 'ta <name>')"
        for session in (tmux list-sessions 2>/dev/null)
            set name (echo $session | cut -d: -f1)
            set info (echo $session | sed 's/^[^:]*: //')
            echo "  • $name: $info"
        end
    end

    set_color normal
    echo ""
end