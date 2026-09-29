# Start an interactive Claude session on a set model at medium effort.
#   opus review pr #123        sonnet /code-review 123
# The rest of the line is the first prompt, so slash commands and skills work.
# A leading flag passes everything through to claude as-is: `opus -c`.
_claude_model() {
    local model=$1; shift
    local -a cmd=(claude --model "$model" --effort medium)
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
# or `sonnet` so the prompt arrives verbatim (and history records it quoted).
# Lines already starting with a quote or a flag are left alone.
_claude_quote_prompt() {
    emulate -L zsh
    setopt localoptions extendedglob
    [[ $BUFFER == (#b)([[:space:]]#(opus|sonnet)[[:space:]]##)(*) ]] || return 0
    local head=$match[1] rest=${match[3]%%[[:space:]]#}
    [[ -n $rest && $rest != [-\'\"\$]* ]] || return 0
    BUFFER=$head${(qq)rest}
}

# noglob covers the cases the ENTER widget skips, e.g. `cd x && opus why?`.
# Defined here rather than in .zshrc: an existing alias blocks the function
# definition of the same name.
alias opus="noglob opus" sonnet="noglob sonnet"
