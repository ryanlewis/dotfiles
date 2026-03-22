function slugify --description "Generate a kebab-case slug from text using AI"
    # Read from stdin or args
    set -l input
    if not isatty stdin
        set input (cat | string collect)
    end
    if test (count $argv) -gt 0
        if test -n "$input"
            set input "$input\n"(string join ' ' $argv)
        else
            set input (string join ' ' $argv)
        end
    end

    if test -z "$input"
        echo "Usage: slugify <text>"
        echo "       echo 'some text' | slugify"
        return 1
    end

    # Truncate and sanitise
    set -l clean (string sub -l 200 "$input" | string replace -ra '[^a-zA-Z0-9 ]' ' ' | string trim)

    if command -q aichat
        aichat "Output ONLY a 2-3 word kebab-case slug for: $clean" 2>/dev/null | string trim
    else if command -q claude
        claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt='' "Output ONLY a 2-3 word kebab-case slug for: $clean" 2>/dev/null | string trim
    else
        echo "Error: aichat or claude required" >&2
        return 1
    end
end
