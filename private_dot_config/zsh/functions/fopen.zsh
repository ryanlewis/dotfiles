# Fuzzy find and open file
fopen() {
    local file
    file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
    if [[ -n $file ]]; then
        if [[ -n $EDITOR ]]; then
            "$EDITOR" "$file"
        else
            open "$file"
        fi
    fi
}
