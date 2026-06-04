# Fuzzy change directory
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git | fzf --preview 'ls -la {}')
    [[ -n $dir ]] && cd "$dir"
}
