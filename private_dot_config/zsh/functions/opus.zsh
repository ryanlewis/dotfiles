# Start an interactive Claude session on a set model at medium effort.
#   opus review pr #123        sonnet /code-review 123
# The rest of the line is the first prompt, so slash commands and skills work.
# Leading `-n <name>` sets the session name and `-e <effort>` the effort
# (l/m/h/x for low/medium/high/xhigh, or a full level such as max):
#   opus -n triage -e h why is ci red?
# Flags after the first prompt word are part of the prompt. Any other leading
# flag passes everything through to claude as-is: `opus -c`.
_claude_model() {
    local model=$1 effort=medium; shift
    local -a extra
    while (( $# >= 2 )); do
        case $1 in
            -n) extra+=(--name "$2") ;;
            -e) case $2 in
                    l) effort=low ;;
                    m) effort=medium ;;
                    h) effort=high ;;
                    x) effort=xhigh ;;
                    *) effort=$2 ;;
                esac ;;
            *)  break ;;
        esac
        shift 2
    done
    local -a cmd=(claude --model "$model" --effort "$effort" "${extra[@]}")
    if [[ $1 == -* ]]; then
        "${cmd[@]}" "$@"
    elif (( $# > 0 )); then
        "${cmd[@]}" -- "$*"
    else
        "${cmd[@]}"
    fi
}

opus()   { _claude_model opus   "$@" }
sonnet() { _claude_model sonnet "$@" }

# At the prompt, `#` starts a comment (INTERACTIVE_COMMENTS) and `'` or `?`
# break the line, so `opus review pr #123` would lose the `#123`. The ENTER
# widget in .zshrc calls this first: it single-quotes everything after `opus`
# or `sonnet` and any leading `-n`/`-e` pairs, so the prompt arrives verbatim
# (and history records it quoted). Lines whose prompt starts with a quote or
# a flag are left alone, as are flag values that start with a quote.
_claude_quote_prompt() {
    emulate -L zsh
    setopt localoptions extendedglob
    [[ $BUFFER == (#b)([[:space:]]#(opus|sonnet)[[:space:]]##((-[ne][[:space:]]##[^[:space:]\'\"]##[[:space:]]##)#))(*) ]] || return 0
    local head=$match[1] rest=${match[5]%%[[:space:]]#}
    [[ -n $rest && $rest != [-\'\"\$]* ]] || return 0
    BUFFER=$head${(qq)rest}
}

# noglob covers the cases the ENTER widget skips, e.g. `cd x && opus why?`.
# Defined here rather than in .zshrc: an existing alias blocks the function
# definition of the same name.
alias opus="noglob opus" sonnet="noglob sonnet"
