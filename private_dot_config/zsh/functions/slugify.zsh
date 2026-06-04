# Generate a kebab-case slug from text using AI
slugify() {
    # Read from stdin or args.
    local input=""
    if [[ ! -t 0 ]]; then
        input=$(cat)
    fi
    if (( $# > 0 )); then
        if [[ -n $input ]]; then
            input="$input"$'\n'"$*"
        else
            input="$*"
        fi
    fi

    if [[ -z $input ]]; then
        echo "Usage: slugify <text>"
        echo "       echo 'some text' | slugify"
        return 1
    fi

    # Truncate to 200 chars, replace non-alphanumerics with spaces, trim.
    local clean=${input[1,200]}
    clean=${clean//[^a-zA-Z0-9 ]/ }
    clean=${clean##[[:space:]]##}
    clean=${clean%%[[:space:]]##}

    if command -v aichat >/dev/null; then
        aichat "Output ONLY a 2-3 word kebab-case slug for: $clean" 2>/dev/null | tr -d '\n'
    elif command -v claude >/dev/null; then
        claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt='' "Output ONLY a 2-3 word kebab-case slug for: $clean" 2>/dev/null | tr -d '\n'
    else
        echo "Error: aichat or claude required" >&2
        return 1
    fi
}
