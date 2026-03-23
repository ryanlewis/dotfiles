#!/bin/sh
# tmux window-name formatter
# Modes:
#   label <cmd>             -> friendly command name, empty for fish
#   path  <cmd> <path>      -> shortened path (command) or full path (fish)
#   <cmd> <path>            -> combined "cmd:short" or "full" (for #W)

case "$1" in
    label|path) mode="$1"; cmd="$2"; full_path="$3" ;;
    *)          mode="combined"; cmd="$1"; full_path="$2" ;;
esac

# Normalise versioned binaries (e.g. 2.1.81 -> claude)
case "$cmd" in
    [0-9]*)
        for link in "$HOME/.local/bin"/*; do
            [ -L "$link" ] || continue
            case "$(readlink "$link")" in
                */"$cmd") cmd="${link##*/}"; break ;;
            esac
        done
        ;;
esac

# Replace $HOME with ~
case "$full_path" in
    "$HOME"/*) path="~/${full_path#"$HOME"/}" ;;
    "$HOME")   path="~" ;;
    *)         path="$full_path" ;;
esac

# Shorten path: abbreviate all components except the last to first char
shorten() {
    printf '%s' "$1" | awk -F/ '{
        for (i = 1; i <= NF; i++) {
            if (i < NF) {
                if ($i == "~") printf "~"
                else if ($i != "") printf "%s", substr($i, 1, 1)
                printf "/"
            } else {
                printf "%s", $i
            }
        }
    }'
}

is_shell() { [ "$cmd" = "fish" ]; }

case "$mode" in
    label)
        is_shell || printf '%s' "$cmd"
        ;;
    path)
        if is_shell; then
            printf '%s' "$path"
        else
            shorten "$path"
        fi
        ;;
    combined)
        if is_shell; then
            printf '%s' "$path"
        else
            printf '%s:%s' "$cmd" "$(shorten "$path")"
        fi
        ;;
esac
