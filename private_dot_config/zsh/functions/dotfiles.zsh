# Manage dotfiles with chezmoi
dotfiles() {
    local cmd=$1
    local -a remaining_args
    remaining_args=("${@:2}")

    case $cmd in
        edit|e)
            # Go to chezmoi source directory.
            cd "$(chezmoi source-path)" || return
            echo "📍 Now in chezmoi source: $(pwd)"
            echo ""
            echo "📝 Edit files, then use:"
            echo "   dotfiles diff    # Preview changes"
            echo "   dotfiles apply   # Apply changes locally"
            echo "   dotfiles push    # Commit and push all changes"
            ;;

        diff|d)
            chezmoi diff "${remaining_args[@]}"
            ;;

        apply|a)
            chezmoi apply "${remaining_args[@]}"
            echo "✅ Changes applied locally"
            ;;

        push|p)
            local message="${remaining_args[*]}"
            [[ -z $message ]] && message="Update dotfiles"

            cd "$(chezmoi source-path)" || return
            chezmoi git add -A
            chezmoi git commit -m "$message" || echo "Nothing to commit"
            chezmoi git push
            echo "📤 Changes pushed to GitHub"
            ;;

        pull|update|u)
            chezmoi update
            echo "📥 Updated from GitHub and applied"
            ;;

        status|s)
            chezmoi git status
            ;;

        log|l)
            chezmoi git log --oneline -10
            ;;

        *)
            echo "Usage: dotfiles <command> [args]"
            echo ""
            echo "Commands:"
            echo "  edit, e        - Go to chezmoi source directory for editing"
            echo "  diff, d        - Preview what would change with apply"
            echo "  apply, a       - Apply changes locally"
            echo "  push, p [msg]  - Commit and push all changes"
            echo "  pull, u        - Pull latest changes and apply (alias: update)"
            echo "  status, s      - Show git status"
            echo "  log, l         - Show recent commits"
            echo ""
            echo "Examples:"
            echo "  dotfiles edit            # Start editing session"
            echo "  dotfiles diff            # See pending changes"
            echo "  dotfiles apply           # Apply changes"
            echo "  dotfiles push 'Add vim'  # Commit and push with message"
            echo "  dotfiles pull            # Update from GitHub"
            ;;
    esac
}
