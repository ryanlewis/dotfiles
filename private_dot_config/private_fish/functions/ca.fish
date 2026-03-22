function ca --description "Spawn and manage Claude agents in tmux worktrees"
    set -l cmd $argv[1]

    switch "$cmd"
        case ls list
            _ca_list
        case attach a
            _ca_attach $argv[2]
        case rm remove
            _ca_remove $argv[2]
        case help --help -h ""
            _ca_help
        case '*'
            _ca_spawn $argv
    end
end

function _ca_help
    echo "Usage: ca <branch> [-- <prompt>]    Spawn a Claude agent"
    echo "       ca <command>"
    echo ""
    echo "Commands:"
    echo "  ls              List running agents"
    echo "  attach, a       Attach to an agent's window/session"
    echo "  rm, remove      Kill agent and clean up worktree"
    echo "  help, --help    Show this help"
    echo ""
    echo "Options:"
    echo "  -s              Create a new tmux session instead of a window"
    echo ""
    echo "Examples:"
    echo "  ca fix-auth -- Fix the session timeout to 24 hours"
    echo "  ca -s fix-auth -- Fix auth in a separate session"
    echo "  ca fix-auth                    # No prompt, just open Claude"
    echo "  ca ls"
    echo "  ca attach fix-auth"
    echo "  ca rm fix-auth"
end

function _ca_spawn
    set -l session_mode false
    set -l branch ""
    set -l prompt_parts
    set -l found_separator false

    # Parse arguments
    for arg in $argv
        if test "$arg" = "-s"
            set session_mode true
            continue
        end
        if test "$arg" = "--"
            set found_separator true
            continue
        end
        if test "$found_separator" = true
            set -a prompt_parts $arg
        else if test -z "$branch"
            set branch $arg
        end
    end

    if test -z "$branch"
        echo (set_color red)"Error: branch name required"(set_color normal)
        echo "Usage: ca <branch> [-- <prompt>]"
        return 1
    end

    # Check dependencies
    if not command -q wt
        echo (set_color red)"Error: worktrunk (wt) not installed"(set_color normal)
        return 1
    end

    # Build the wt command
    set -l prompt_str (string join ' ' $prompt_parts)
    set -l wt_cmd "wt switch --create $branch -x claude"
    if test -n "$prompt_str"
        set wt_cmd "$wt_cmd -- '$prompt_str'"
    end

    # Get repo name from git
    set -l repo_name (basename (git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null)
    if test -z "$repo_name"
        echo (set_color red)"Error: not in a git repository"(set_color normal)
        return 1
    end

    if test "$session_mode" = true
        # Create new session
        if tmux has-session -t "$branch" 2>/dev/null
            echo (set_color red)"Error: tmux session '$branch' already exists"(set_color normal)
            return 1
        end

        tmux new-session -d -s "$branch"
        tmux set-option -t "$branch" @ca-agent true
        tmux set-option -t "$branch" @ca-repo "$repo_name"
        tmux set-option -t "$branch" @ca-branch "$branch"
        tmux set-option -t "$branch" @ca-prompt "$prompt_str"

        # Set window options too for consistency
        tmux set-option -w -t "$branch" @ca-agent true
        tmux set-option -w -t "$branch" @ca-repo "$repo_name"
        tmux set-option -w -t "$branch" @ca-branch "$branch"
        tmux set-option -w -t "$branch" @ca-prompt "$prompt_str"

        tmux send-keys -t "$branch" "$wt_cmd" Enter

        echo (set_color green)"  $branch"(set_color normal)
        echo (set_color brblack)"  Session created, Claude launched"(set_color normal)
        echo (set_color brblack)"  Attach: "(set_color normal)"ca attach $branch"
    else
        # Create new window in current session
        if not set -q TMUX
            echo (set_color red)"Error: not in a tmux session (use -s to create a new session)"(set_color normal)
            return 1
        end

        tmux new-window -n "$branch"
        tmux set-option -w @ca-agent true
        tmux set-option -w @ca-repo "$repo_name"
        tmux set-option -w @ca-branch "$branch"
        tmux set-option -w @ca-prompt "$prompt_str"

        tmux send-keys -t "$branch" "$wt_cmd" Enter

        # Switch back to the original window
        tmux last-window

        echo (set_color green)"  $branch"(set_color normal)
        echo (set_color brblack)"  Window created, Claude launched"(set_color normal)
        echo (set_color brblack)"  Attach: "(set_color normal)"ca attach $branch"
    end
end

function _ca_list
    set -l found false

    # Get all sessions
    for session in (tmux list-sessions -F '#{session_name}' 2>/dev/null)
        set -l session_agents

        # Check each window in this session
        for window_info in (tmux list-windows -t "$session" -F '#{window_index}:#{window_name}:#{pane_current_command}' 2>/dev/null)
            set -l parts (string split ':' $window_info)
            set -l win_idx $parts[1]
            set -l win_name $parts[2]
            set -l pane_cmd $parts[3]

            # Check if this window is a ca agent
            set -l is_agent (tmux show-options -w -t "$session:$win_idx" -v @ca-agent 2>/dev/null)
            if test "$is_agent" = "true"
                set -l branch (tmux show-options -w -t "$session:$win_idx" -v @ca-branch 2>/dev/null)
                set -l prompt (tmux show-options -w -t "$session:$win_idx" -v @ca-prompt 2>/dev/null)
                set -l repo (tmux show-options -w -t "$session:$win_idx" -v @ca-repo 2>/dev/null)

                # Determine status from pane command
                set -l status_str
                if string match -q '*claude*' "$pane_cmd"
                    set status_str (set_color green)"running"(set_color normal)
                else
                    set status_str (set_color yellow)"exited"(set_color normal)
                end

                # Truncate prompt
                set -l display_prompt "$prompt"
                if test (string length "$prompt") -gt 40
                    set display_prompt (string sub -l 37 "$prompt")"..."
                end

                set -a session_agents "$win_name|$win_idx|$status_str|$display_prompt"
                set found true
            end
        end

        # Print session group if it has agents
        if test (count $session_agents) -gt 0
            echo (set_color magenta)"  $session"(set_color normal)(set_color brblack)" ("(count $session_agents)" agent"(test (count $session_agents) -gt 1 && echo "s")")"(set_color normal)
            for agent in $session_agents
                set -l parts (string split '|' $agent)
                printf "    %-20s window %-4s %s  %s\n" \
                    (set_color cyan)$parts[1](set_color normal) \
                    $parts[2] \
                    $parts[3] \
                    (set_color brblack)$parts[4](set_color normal)
            end
            echo ""
        end
    end

    if test "$found" = false
        echo (set_color brblack)"  No agents running"(set_color normal)
    end
end

function _ca_attach
    set -l name $argv[1]

    if test -z "$name"
        echo (set_color red)"Error: agent name required"(set_color normal)
        echo "Usage: ca attach <branch>"
        return 1
    end

    # Try window in current session first
    if set -q TMUX
        if tmux select-window -t "$name" 2>/dev/null
            return 0
        end
    end

    # Try as a session name
    if tmux switch-client -t "$name" 2>/dev/null
        return 0
    end

    # Try attaching from outside tmux
    if tmux attach -t "$name" 2>/dev/null
        return 0
    end

    echo (set_color red)"Error: no agent found with name '$name'"(set_color normal)
    return 1
end

function _ca_remove
    set -l name $argv[1]

    if test -z "$name"
        echo (set_color red)"Error: agent name required"(set_color normal)
        echo "Usage: ca rm <branch>"
        return 1
    end

    # Find and kill the window/session
    set -l killed false

    # Check windows across all sessions
    for session in (tmux list-sessions -F '#{session_name}' 2>/dev/null)
        for window_info in (tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null)
            set -l parts (string split ':' $window_info)
            set -l win_idx $parts[1]
            set -l win_name $parts[2]

            if test "$win_name" = "$name"
                set -l is_agent (tmux show-options -w -t "$session:$win_idx" -v @ca-agent 2>/dev/null)
                if test "$is_agent" = "true"
                    tmux kill-window -t "$session:$win_idx"
                    set killed true
                    break
                end
            end
        end
        test "$killed" = true && break
    end

    # Also check if it's a session
    if test "$killed" = false
        if tmux has-session -t "$name" 2>/dev/null
            set -l is_agent (tmux show-options -t "$name" -v @ca-agent 2>/dev/null)
            if test "$is_agent" = "true"
                tmux kill-session -t "$name"
                set killed true
            end
        end
    end

    if test "$killed" = false
        echo (set_color red)"Error: no agent found with name '$name'"(set_color normal)
        return 1
    end

    # Clean up worktree
    if command -q wt
        wt remove "$name" 2>/dev/null
        and echo (set_color green)"  Removed agent and worktree: $name"(set_color normal)
        or echo (set_color yellow)"  Killed agent: $name"(set_color normal)(set_color brblack)" (worktree may need manual cleanup)"(set_color normal)
    else
        echo (set_color green)"  Killed agent: $name"(set_color normal)
    end
end
