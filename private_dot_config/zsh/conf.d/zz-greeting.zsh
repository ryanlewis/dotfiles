# Greeting on interactive shell start — system info.
# `zz-` prefix so it runs after the env-setting conf.d files.
#
# Hot path — avoid forking where zsh has a built-in: $OSTYPE replaces `uname`
# (called twice), $HOST replaces `hostname`, and a single `uptime` capture sliced
# with parameter expansion replaces a second `uptime` plus `sed`/`awk`. Only
# `sw_vers` and one `uptime` (+ `uptime -p` on Linux) still fork.
() {
    [[ -o interactive ]] || return

    local cyan=$'\e[36m' yellow=$'\e[33m' reset=$'\e[0m'
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
    print
}
