# Yazi file manager with directory changing on exit
y() {
    local tmp cwd
    tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    command yazi "$@" --cwd-file="$tmp"
    # yazi writes the final directory (NUL/no trailing newline) to the temp file.
    IFS= read -r -d '' cwd < "$tmp"
    if [[ -n $cwd && $cwd != "$PWD" && -d $cwd ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
