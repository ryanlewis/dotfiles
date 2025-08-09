function yank
    # This version should work in most cases
    base64 -w0 | xargs -0 printf "\033]52;c;%s\007"
end
