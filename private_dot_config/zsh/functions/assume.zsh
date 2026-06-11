# Assume AWS role via granted
# Sources the bash/zsh assume script from mise-installed granted.
assume() {
    local granted_path assume_script
    granted_path=$(mise where aqua:common-fate/granted 2>/dev/null)
    if [[ -z $granted_path ]]; then
        echo "Error: granted not installed via mise. Run: mise install" >&2
        return 1
    fi

    # granted ships `assume` (bash/zsh) alongside `assume.fish`.
    assume_script="$granted_path/assume"
    if [[ -f $assume_script ]]; then
        # The script only detects alias-based invocation (`alias assume=". assume"`).
        # Sourced from a function instead, we must declare the integration ourselves:
        # GRANTED_ALIAS_CONFIGURED stops assumego prompting to install an alias, and
        # GRANTED_RETURN_STATUS makes the script return assumego's real exit status.
        local -x GRANTED_ALIAS_CONFIGURED=true
        local GRANTED_RETURN_STATUS=true
        source "$assume_script" "$@"
    else
        echo "Error: assume not found at $assume_script" >&2
        return 1
    fi
}
