# Greeting on interactive shell start — system info.
# `zz-` prefix so it runs after the env-setting conf.d files.
#
# Hot path — avoid forking where zsh has a built-in: $OSTYPE replaces `uname`
# (called twice), $HOST replaces `hostname`, and a single `uptime` capture sliced
# with parameter expansion replaces a second `uptime` plus `sed`/`awk`. The
# macOS version (`sw_vers`) is cached (see below), so only one `uptime`
# (+ `uptime -p` on Linux) still forks per start.
() {
    [[ -o interactive ]] || return

    local cyan=$'\e[36m' yellow=$'\e[33m' reset=$'\e[0m'
    local os_name up uptime_str load

    if [[ $OSTYPE == darwin* ]]; then
        # sw_vers is a ~5ms fork (endpoint-security scanned) for a value that
        # only changes on an OS update. Cache it, re-forking only when the system
        # version plist is newer than the cache (a fork-free `-nt` mtime test).
        local vfile="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/os-version"
        local plist=/System/Library/CoreServices/SystemVersion.plist
        if [[ -s $vfile && ! $plist -nt $vfile ]]; then
            os_name="macOS $(<$vfile)"
        else
            os_name="macOS $(sw_vers -productVersion 2>/dev/null)"
            print -r -- "${os_name#macOS }" >| $vfile 2>/dev/null
        fi
    else
        # lsb_release is a ~10ms subprocess (it shells out repeatedly) for a
        # value that already lives, fork-free, in /etc/os-release. Read
        # PRETTY_NAME directly with a builtin read loop; fall back to
        # lsb_release, then a bare "Linux", on the rare host without it.
        local osrel=/etc/os-release line
        os_name=""
        if [[ -r $osrel ]]; then
            while IFS= read -r line; do
                if [[ $line == PRETTY_NAME=* ]]; then
                    os_name=${${line#PRETTY_NAME=}//\"/}   # strip wrapping quotes
                    break
                fi
            done < $osrel
        fi
        [[ -n $os_name ]] || os_name=$(lsb_release -ds 2>/dev/null || echo Linux)
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
