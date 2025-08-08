function fcd --description "Fuzzy change directory"
    set -l dir (fd --type d --hidden --follow --exclude .git | fzf --preview 'ls -la {}')
    if test -n "$dir"
        cd "$dir"
    end
end