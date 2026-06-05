# Custom greeting with system information.
#
# Hot path — avoid forking where fish has a built-in: $hostname replaces
# `hostname`, `uname` is called once instead of twice, and a single `uptime`
# capture sliced with `string` builtins replaces a second `uptime` plus
# `sed`/`awk`. tmux sessions are captured once and parsed with `string split`
# rather than an `echo | cut` + `echo | sed` per session.
function fish_greeting
    set -l os (uname)

    set_color cyan
    set -l os_name
    if test "$os" = Darwin
        set os_name "macOS "(sw_vers -productVersion 2>/dev/null)
    else
        set os_name (lsb_release -ds 2>/dev/null || echo Linux)
    end
    echo "Welcome to $hostname • $os_name"

    set_color yellow
    set -l up (uptime)
    set -l load (string replace -r '^.*: ' '' -- $up)   # text after the final ": "
    set -l uptime_str
    if test "$os" = Darwin
        set uptime_str (string replace -r '^.*up +' '' -- $up | string replace -r ',.*' '')
    else
        set uptime_str (uptime -p 2>/dev/null)
        test -n "$uptime_str"; or set uptime_str (string replace -r '^.*up +' '' -- $up | string replace -r ',.*' '')
    end
    echo "Uptime: $uptime_str • Load: $load"

    # tmux sessions only if a server is running. Capture the list once and reuse.
    if type -q tmux
        set -l sessions (tmux list-sessions 2>/dev/null)
        if test -n "$sessions"
            set_color magenta
            echo ""
            if set -q TMUX
                set -l current_session (tmux display-message -p '#S')
                echo "Tmux sessions: (Ctrl+A S to switch)"
                for session in $sessions
                    set -l parts (string split -m1 ": " -- $session)
                    if test "$parts[1]" = "$current_session"
                        set_color green
                        echo "  ▸ $parts[1]: $parts[2] ← current"
                        set_color magenta
                    else
                        echo "  • $parts[1]: $parts[2]"
                    end
                end
            else
                echo "Tmux sessions: (attach with 'ta <name>')"
                for session in $sessions
                    set -l parts (string split -m1 ": " -- $session)
                    echo "  • $parts[1]: $parts[2]"
                end
            end
        end
    end

    set_color normal
    echo ""
end
