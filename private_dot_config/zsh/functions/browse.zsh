# Read-only code browsing in nvim (see nvim lua/custom/plugins/browse.lua)
# browse [dir|file]
browse() {
    if [[ -d ${1:-.} ]]; then
        (cd "${1:-.}" && nvim -R --cmd 'let g:browse=1')
    else
        nvim -R --cmd 'let g:browse=1' "$@"
    fi
}
