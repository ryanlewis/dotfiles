# Fuzzy grep with preview (note: intentionally shadows the system fgrep, as in
# the fish setup — rg replaces grep here anyway).
fgrep() {
    if (( $# == 0 )); then
        echo "Usage: fgrep <search-term>"
        return 1
    fi

    local search_term=$1 selection file line
    selection=$(rg --color=always --line-number --no-heading --smart-case "$search_term" | \
        fzf --ansi \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview 'bat --color=always {1} --highlight-line {2}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')

    if [[ -n $selection ]]; then
        file=$(echo "$selection" | cut -d: -f1)
        line=$(echo "$selection" | cut -d: -f2)
        if [[ -n $EDITOR ]]; then
            "$EDITOR" "+$line" "$file"
        else
            echo "Selected: $file:$line"
        fi
    fi
}
