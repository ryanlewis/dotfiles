# Greeting on interactive shell start — system info.
# `zz-` prefix so it runs after the env-setting conf.d files.
#
# Hot path — avoid forking where zsh has a built-in: $OSTYPE replaces `uname`
# (called twice), $HOST replaces `hostname`, and a single `uptime` capture sliced
# with parameter expansion replaces a second `uptime` plus `sed`/`awk`. tmux
# sessions are captured once instead of probed-then-relisted. Only `sw_vers` and
# one `uptime` (+ `uptime -p` on Linux) still fork.
() {
    [[ -o interactive ]] || return

    local cyan=$'\e[36m' yellow=$'\e[33m' magenta=$'\e[35m' green=$'\e[32m' reset=$'\e[0m'
    local os_name up uptime_str load

    if [[ $OSTYPE == darwin* ]]; then
        os_name="macOS $(sw_vers -productVersion 2>/dev/null)"
    else
        os_name=$(lsb_release -ds 2>/dev/null || echo Linux)
    fi
    print -r -- "${cyan}Welcome to $HOST • ${os_name}${reset}"

    up=$(uptime)
    load=${up##*: }                          # text after the final ": " = load averages
    if [[ $OSTYPE == darwin* ]]; then
        uptime_str=${${up#*up }%%,*}         # between "up " and the first comma
    else
        uptime_str=$(uptime -p 2>/dev/null) || uptime_str=${${up#*up }%%,*}
    fi
    print -r -- "${yellow}Uptime: ${uptime_str} • Load: ${load}${reset}"

    # tmux sessions, only when a server is running. Capture the list once and
    # reuse it for both the existence check and the per-session output.
    if (( $+commands[tmux] )); then
        local sessions
        sessions=$(tmux list-sessions 2>/dev/null)
        if [[ -n $sessions ]]; then
            local line name info current_session
            print
            if [[ -n $TMUX ]]; then
                current_session=$(tmux display-message -p '#S')
                print -r -- "${magenta}Tmux sessions: (Ctrl+A S to switch)${reset}"
                while IFS= read -r line; do
                    name=${line%%:*}; info=${line#*: }
                    if [[ $name == $current_session ]]; then
                        print -r -- "${green}  ▸ $name: $info ← current${reset}"
                    else
                        print -r -- "${magenta}  • $name: $info${reset}"
                    fi
                done <<< "$sessions"
            else
                print -r -- "${magenta}Tmux sessions: (attach with 'ta <name>')${reset}"
                while IFS= read -r line; do
                    name=${line%%:*}; info=${line#*: }
                    print -r -- "${magenta}  • $name: $info${reset}"
                done <<< "$sessions"
            fi
        fi
    fi
    print
}
