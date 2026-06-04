# Spawn and manage Claude agents in tmux worktrees
ca() {
    local cmd=$1
    case $cmd in
        ls|list)            _ca_list ;;
        attach|a)           _ca_attach "$2" ;;
        rm|remove)          _ca_remove "$2" ;;
        help|--help|-h|"")  _ca_help ;;
        *)                  _ca_spawn "$@" ;;
    esac
}

_ca_help() {
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
}

_ca_spawn() {
    local C_red=$'\e[31m' C_green=$'\e[32m' C_brblack=$'\e[90m' C_reset=$'\e[0m'
    local session_mode=false branch="" found_separator=false
    local -a prompt_parts
    local arg

    # Parse arguments.
    for arg in "$@"; do
        if [[ $arg == "-s" ]]; then
            session_mode=true
            continue
        fi
        if [[ $arg == "--" ]]; then
            found_separator=true
            continue
        fi
        if [[ $found_separator == true ]]; then
            prompt_parts+=("$arg")
        elif [[ -z $branch ]]; then
            branch=$arg
        fi
    done

    if [[ -z $branch ]]; then
        print -r -- "${C_red}Error: branch name required${C_reset}"
        echo "Usage: ca <branch> [-- <prompt>]"
        return 1
    fi

    # Check dependencies.
    if ! command -v wt >/dev/null; then
        print -r -- "${C_red}Error: worktrunk (wt) not installed${C_reset}"
        return 1
    fi

    # Build the wt command.
    local prompt_str="${prompt_parts[*]}"
    local wt_cmd="wt switch --create $branch -x claude"
    if [[ -n $prompt_str ]]; then
        wt_cmd="$wt_cmd -- '$prompt_str'"
    fi

    # Get repo name from git.
    local repo_name
    repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
    if [[ -z $repo_name ]]; then
        print -r -- "${C_red}Error: not in a git repository${C_reset}"
        return 1
    fi

    if [[ $session_mode == true ]]; then
        # Create new session.
        if tmux has-session -t "$branch" 2>/dev/null; then
            print -r -- "${C_red}Error: tmux session '$branch' already exists${C_reset}"
            return 1
        fi

        tmux new-session -d -s "$branch"
        tmux set-option -t "$branch" @ca-agent true
        tmux set-option -t "$branch" @ca-repo "$repo_name"
        tmux set-option -t "$branch" @ca-branch "$branch"
        tmux set-option -t "$branch" @ca-prompt "$prompt_str"

        # Set window options too for consistency.
        tmux set-option -w -t "$branch" @ca-agent true
        tmux set-option -w -t "$branch" @ca-repo "$repo_name"
        tmux set-option -w -t "$branch" @ca-branch "$branch"
        tmux set-option -w -t "$branch" @ca-prompt "$prompt_str"

        tmux send-keys -t "$branch" "$wt_cmd" Enter

        print -r -- "${C_green}  $branch${C_reset}"
        print -r -- "${C_brblack}  Session created, Claude launched${C_reset}"
        print -r -- "${C_brblack}  Attach: ${C_reset}ca attach $branch"
    else
        # Create new window in current session.
        if [[ -z $TMUX ]]; then
            print -r -- "${C_red}Error: not in a tmux session (use -s to create a new session)${C_reset}"
            return 1
        fi

        tmux new-window -n "$branch"
        tmux set-option -w @ca-agent true
        tmux set-option -w @ca-repo "$repo_name"
        tmux set-option -w @ca-branch "$branch"
        tmux set-option -w @ca-prompt "$prompt_str"

        tmux send-keys -t "$branch" "$wt_cmd" Enter

        # Switch back to the original window.
        tmux last-window

        print -r -- "${C_green}  $branch${C_reset}"
        print -r -- "${C_brblack}  Window created, Claude launched${C_reset}"
        print -r -- "${C_brblack}  Attach: ${C_reset}ca attach $branch"
    fi
}

_ca_list() {
    local C_green=$'\e[32m' C_yellow=$'\e[33m' C_magenta=$'\e[35m' C_cyan=$'\e[36m' \
          C_brblack=$'\e[90m' C_reset=$'\e[0m'
    local found=false
    local session window_info win_idx win_name pane_cmd is_agent branch prompt repo status_str display_prompt
    local -a session_agents parts

    for session in ${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"}; do
        session_agents=()

        for window_info in ${(f)"$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}:#{pane_current_command}' 2>/dev/null)"}; do
            parts=( ${(s.:.)window_info} )
            win_idx=${parts[1]}; win_name=${parts[2]}; pane_cmd=${parts[3]}

            is_agent=$(tmux show-options -w -t "$session:$win_idx" -v @ca-agent 2>/dev/null)
            if [[ $is_agent == true ]]; then
                branch=$(tmux show-options -w -t "$session:$win_idx" -v @ca-branch 2>/dev/null)
                prompt=$(tmux show-options -w -t "$session:$win_idx" -v @ca-prompt 2>/dev/null)
                repo=$(tmux show-options -w -t "$session:$win_idx" -v @ca-repo 2>/dev/null)

                if [[ $pane_cmd == *claude* ]]; then
                    status_str="${C_green}running${C_reset}"
                else
                    status_str="${C_yellow}exited${C_reset}"
                fi

                display_prompt=$prompt
                if (( ${#prompt} > 40 )); then
                    display_prompt="${prompt[1,37]}..."
                fi

                session_agents+=( "$win_name|$win_idx|$status_str|$display_prompt" )
                found=true
            fi
        done

        if (( ${#session_agents} > 0 )); then
            local count=${#session_agents} plural=""
            (( count > 1 )) && plural="s"
            print -r -- "${C_magenta}  $session${C_reset}${C_brblack} ($count agent$plural)${C_reset}"
            local agent
            local -a agent_parts
            for agent in $session_agents; do
                agent_parts=( ${(s:|:)agent} )
                printf "    ${C_cyan}%-20s${C_reset} window %-4s %s  ${C_brblack}%s${C_reset}\n" \
                    "${agent_parts[1]}" "${agent_parts[2]}" "${agent_parts[3]}" "${agent_parts[4]}"
            done
            print
        fi
    done

    if [[ $found == false ]]; then
        print -r -- "${C_brblack}  No agents running${C_reset}"
    fi
}

_ca_attach() {
    local C_red=$'\e[31m' C_reset=$'\e[0m'
    local name=$1

    if [[ -z $name ]]; then
        print -r -- "${C_red}Error: agent name required${C_reset}"
        echo "Usage: ca attach <branch>"
        return 1
    fi

    # Try window in current session first.
    if [[ -n $TMUX ]]; then
        tmux select-window -t "$name" 2>/dev/null && return 0
    fi
    # Try as a session name.
    tmux switch-client -t "$name" 2>/dev/null && return 0
    # Try attaching from outside tmux.
    tmux attach -t "$name" 2>/dev/null && return 0

    print -r -- "${C_red}Error: no agent found with name '$name'${C_reset}"
    return 1
}

_ca_remove() {
    local C_red=$'\e[31m' C_green=$'\e[32m' C_yellow=$'\e[33m' C_brblack=$'\e[90m' C_reset=$'\e[0m'
    local name=$1

    if [[ -z $name ]]; then
        print -r -- "${C_red}Error: agent name required${C_reset}"
        echo "Usage: ca rm <branch>"
        return 1
    fi

    local killed=false session window_info win_idx win_name is_agent
    local -a parts

    # Check windows across all sessions.
    for session in ${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"}; do
        for window_info in ${(f)"$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}' 2>/dev/null)"}; do
            parts=( ${(s.:.)window_info} )
            win_idx=${parts[1]}; win_name=${parts[2]}

            if [[ $win_name == "$name" ]]; then
                is_agent=$(tmux show-options -w -t "$session:$win_idx" -v @ca-agent 2>/dev/null)
                if [[ $is_agent == true ]]; then
                    tmux kill-window -t "$session:$win_idx"
                    killed=true
                    break
                fi
            fi
        done
        [[ $killed == true ]] && break
    done

    # Also check if it's a session.
    if [[ $killed == false ]]; then
        if tmux has-session -t "$name" 2>/dev/null; then
            is_agent=$(tmux show-options -t "$name" -v @ca-agent 2>/dev/null)
            if [[ $is_agent == true ]]; then
                tmux kill-session -t "$name"
                killed=true
            fi
        fi
    fi

    if [[ $killed == false ]]; then
        print -r -- "${C_red}Error: no agent found with name '$name'${C_reset}"
        return 1
    fi

    # Clean up worktree.
    if command -v wt >/dev/null; then
        if wt remove "$name" 2>/dev/null; then
            print -r -- "${C_green}  Removed agent and worktree: $name${C_reset}"
        else
            print -r -- "${C_yellow}  Killed agent: $name${C_reset}${C_brblack} (worktree may need manual cleanup)${C_reset}"
        fi
    else
        print -r -- "${C_green}  Killed agent: $name${C_reset}"
    fi
}
