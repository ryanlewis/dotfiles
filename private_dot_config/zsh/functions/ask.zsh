# One-shot question to Claude — no session, no repo context, plain text out.
#   ask   sonnet (default)   askh   haiku (fast)   asko   opus (hard ones)
# Accepts a question as arguments, on stdin, or both.
_ask() {
    local model=$1; shift
    local -a tools=(--tools '')

    while [[ $1 == -* ]]; do
        case $1 in
            -w|--web)
                tools=(--tools 'WebSearch,WebFetch' --allowed-tools 'WebSearch,WebFetch')
                shift ;;
            -h|--help)
                print "Usage: ask|askh|asko [-w] <question>"
                print "       <command> | ask [-w] [<question>]"
                print
                print "  ask     Sonnet — the default"
                print "  askh    Haiku  — quick lookups"
                print "  asko    Opus   — hard questions"
                print "  -w      Allow web search for anything current"
                return 0 ;;
            --) shift; break ;;
            *)  print -u2 "ask: unknown option $1"; return 1 ;;
        esac
    done

    # Build the prompt from piped stdin and/or args.
    local prompt=""
    [[ ! -t 0 ]] && prompt=$(cat)
    if (( $# > 0 )); then
        if [[ -n $prompt ]]; then
            prompt="$prompt"$'\n\n'"$*"
        else
            prompt="$*"
        fi
    fi

    if [[ -z $prompt ]]; then
        print -u2 "Usage: ask <question>   (see: ask --help)"
        return 1
    fi

    command -v claude >/dev/null || { print -u2 "ask: claude not found"; return 1; }

    # Hermetic: no settings, no slash commands, nothing written to session history.
    claude -p \
        --model "$model" \
        --no-session-persistence \
        --disable-slash-commands \
        --setting-sources='' \
        --system-prompt='Answer concisely in plain UK English. No preamble, no restating the question, no closing summary. Prefer a short direct answer over a thorough one.' \
        "${tools[@]}" \
        -- "$prompt"
}

ask()  { _ask sonnet "$@" }
askh() { _ask haiku  "$@" }
asko() { _ask opus   "$@" }

# noglob so `ask why does ctrl+d exit?` needs no quoting (zsh would glob the ?).
# Defined here rather than with the other aliases in .zshrc: that block runs
# before this file is sourced, and an existing alias blocks the function
# definition of the same name.
alias ask="noglob ask" askh="noglob askh" asko="noglob asko"
