function dotfiles --description "Manage dotfiles with chezmoi"
    set -l cmd $argv[1]
    set -l remaining_args $argv[2..-1]

    switch $cmd
        case edit e
            # Go to chezmoi source directory
            cd (chezmoi source-path)
            echo "📍 Now in chezmoi source: "(pwd)
            echo ""
            echo "📝 Edit files, then use:"
            echo "   dotfiles diff    # Preview changes"
            echo "   dotfiles apply   # Apply changes locally"
            echo "   dotfiles push    # Commit and push all changes"

        case diff d
            # Show what would change
            chezmoi diff $remaining_args

        case apply a
            # Apply changes locally
            chezmoi apply $remaining_args
            echo "✅ Changes applied locally"

        case push p
            # Commit and push all changes
            set -l message $remaining_args
            if test -z "$message"
                set message "Update dotfiles"
            end
            
            cd (chezmoi source-path)
            chezmoi git add -A
            chezmoi git commit -m "$message" || echo "Nothing to commit"
            chezmoi git push
            echo "📤 Changes pushed to GitHub"

        case pull update u
            # Pull latest changes and apply
            chezmoi update
            echo "📥 Updated from GitHub and applied"

        case status s
            # Show git status
            chezmoi git status

        case log l
            # Show recent commits
            chezmoi git log --oneline -10

        case '*'
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
            echo "  dotfiles push 'Add vim' # Commit and push with message"
            echo "  dotfiles pull            # Update from GitHub"
    end
end