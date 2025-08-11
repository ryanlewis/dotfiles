# Custom greeting with system information
function fish_greeting
    set_color cyan
    # Get OS name
    if test (uname) = "Darwin"
        set os_name "macOS "(sw_vers -productVersion 2>/dev/null || echo "")
    else
        set os_name (lsb_release -ds 2>/dev/null || echo "Linux")
    end
    
    echo "Welcome to "(hostname)" • "$os_name
    
    set_color yellow
    # Get uptime - macOS doesn't support -p flag
    if test (uname) = "Darwin"
        set uptime_str (uptime | sed 's/.*up //' | sed 's/,.*//')
        echo "Uptime: "$uptime_str" • Load: "(uptime | awk -F'load averages:' '{print $2}')
    else
        echo "Uptime: "(uptime -p 2>/dev/null || uptime)" • Load: "(uptime | awk -F'load average:' '{print $2}')
    end

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