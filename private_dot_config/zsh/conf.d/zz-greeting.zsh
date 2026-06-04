# Greeting on interactive shell start — system info (analogue of fish_greeting).
# `zz-` prefix so it runs after the env-setting conf.d files.
() {
    [[ -o interactive ]] || return

    local cyan=$'\e[36m' yellow=$'\e[33m' magenta=$'\e[35m' green=$'\e[32m' reset=$'\e[0m'
    local os_name uptime_str

    if [[ $(uname) == Darwin ]]; then
        os_name="macOS $(sw_vers -productVersion 2>/dev/null)"
    else
        os_name=$(lsb_release -ds 2>/dev/null || echo Linux)
    fi
    print -r -- "${cyan}Welcome to $(hostname) • ${os_name}${reset}"

    if [[ $(uname) == Darwin ]]; then
        uptime_str=$(uptime | sed 's/.*up //; s/,.*//')
        print -r -- "${yellow}Uptime: ${uptime_str} • Load:$(uptime | awk -F'load averages:' '{print $2}')${reset}"
    else
        uptime_str=$(uptime -p 2>/dev/null || uptime)
        print -r -- "${yellow}Uptime: ${uptime_str} • Load:$(uptime | awk -F'load average:' '{print $2}')${reset}"
    fi

    # tmux sessions, only when a server is running.
    if command -v tmux >/dev/null && tmux list-sessions >/dev/null 2>&1; then
        local line name info current_session
        print
        if [[ -n $TMUX ]]; then
            current_session=$(tmux display-message -p '#S')
            print -r -- "${magenta}Tmux sessions: (Ctrl+A S to switch)${reset}"
            tmux list-sessions 2>/dev/null | while IFS= read -r line; do
                name=${line%%:*}; info=${line#*: }
                if [[ $name == $current_session ]]; then
                    print -r -- "${green}  ▸ $name: $info ← current${reset}"
                else
                    print -r -- "${magenta}  • $name: $info${reset}"
                fi
            done
        else
            print -r -- "${magenta}Tmux sessions: (attach with 'ta <name>')${reset}"
            tmux list-sessions 2>/dev/null | while IFS= read -r line; do
                name=${line%%:*}; info=${line#*: }
                print -r -- "${magenta}  • $name: $info${reset}"
            done
        fi
    fi
    print
}
