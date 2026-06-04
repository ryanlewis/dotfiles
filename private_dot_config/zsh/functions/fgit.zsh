# Interactive git operations with fzf
fgit() {
    if (( $# == 0 )); then
        echo "Usage: fgit <command>"
        echo "Commands:"
        echo "  add      - Stage files interactively"
        echo "  checkout - Checkout branches/files"
        echo "  log      - Browse git log"
        echo "  diff     - View file diffs"
        return 1
    fi

    case $1 in
        add)
            local files
            files=$(git status -s | grep -v "^[AM]" | awk '{print $2}' | \
                fzf -m --preview 'git diff --color=always {}')
            if [[ -n $files ]]; then
                echo "$files" | xargs git add
                git status -s
            fi
            ;;

        checkout)
            local branch
            branch=$(git branch -a | \
                fzf --preview 'git log --oneline --graph --color=always {}' | \
                sed 's/^\*\?[[:space:]]*//' | sed 's#remotes/origin/##')
            [[ -n $branch ]] && git checkout "$branch"
            ;;

        log)
            local commit
            commit=$(git log --oneline --color=always | \
                fzf --ansi --preview 'git show --color=always {1}' | \
                awk '{print $1}')
            [[ -n $commit ]] && git show "$commit"
            ;;

        diff)
            local file
            file=$(git status -s | awk '{print $2}' | \
                fzf --preview 'git diff --color=always {}')
            [[ -n $file ]] && git diff "$file"
            ;;

        *)
            echo "Unknown command: $1"
            return 1
            ;;
    esac
}
