# Open Claude in notes vault (runs in the current pane)
cn() {
    # Build prompt from piped stdin and/or args.
    local prompt=""
    [[ ! -t 0 ]] && prompt=$(cat)
    if (( $# > 0 )); then
        if [[ -n $prompt ]]; then
            prompt="$prompt"$'\n'"$*"
        else
            prompt="$*"
        fi
    fi

    # Subshell so the caller's cwd is untouched; reattach stdin to the
    # terminal in case it was consumed by the pipe above.
    if [[ -n $prompt ]]; then
        ( cd ~/dev/notes && claude "$prompt" </dev/tty )
    else
        ( cd ~/dev/notes && claude )
    fi
}
