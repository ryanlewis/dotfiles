function fgit --description "Interactive git operations with fzf"
    if test (count $argv) -eq 0
        echo "Usage: fgit <command>"
        echo "Commands:"
        echo "  add     - Stage files interactively"
        echo "  checkout - Checkout branches/files"
        echo "  log     - Browse git log"
        echo "  diff    - View file diffs"
        return 1
    end
    
    switch $argv[1]
        case add
            set -l files (git status -s | grep -v "^[AM]" | awk '{print $2}' | \
                fzf -m --preview 'git diff --color=always {}')
            if test -n "$files"
                echo $files | xargs git add
                git status -s
            end
            
        case checkout
            set -l branch (git branch -a | \
                fzf --preview 'git log --oneline --graph --color=always {}' | \
                sed 's/^\*\?\s*//' | sed 's/remotes\/origin\///')
            if test -n "$branch"
                git checkout $branch
            end
            
        case log
            set -l commit (git log --oneline --color=always | \
                fzf --ansi --preview 'git show --color=always {1}' | \
                awk '{print $1}')
            if test -n "$commit"
                git show $commit
            end
            
        case diff
            set -l file (git status -s | awk '{print $2}' | \
                fzf --preview 'git diff --color=always {}')
            if test -n "$file"
                git diff $file
            end
            
        case '*'
            echo "Unknown command: $argv[1]"
            return 1
    end
end