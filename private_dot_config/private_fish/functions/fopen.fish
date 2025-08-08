function fopen --description "Fuzzy find and open file"
    set -l file (fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
    if test -n "$file"
        if test -n "$EDITOR"
            $EDITOR "$file"
        else
            open "$file"
        end
    end
end