function fgrep --description "Fuzzy grep with preview"
    if test (count $argv) -eq 0
        echo "Usage: fgrep <search-term>"
        return 1
    end
    
    set -l search_term $argv[1]
    set -l selection (rg --color=always --line-number --no-heading --smart-case "$search_term" | \
        fzf --ansi \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview 'bat --color=always {1} --highlight-line {2}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
    
    if test -n "$selection"
        set -l file (echo $selection | cut -d: -f1)
        set -l line (echo $selection | cut -d: -f2)
        if test -n "$EDITOR"
            $EDITOR "+$line" "$file"
        else
            echo "Selected: $file:$line"
        end
    end
end