function yank --description "Copy text to clipboard via OSC 52 escape sequence (works over SSH)"
    # Uses OSC 52 escape sequence to copy text to the clipboard
    # This works in terminals that support OSC 52, allowing clipboard access
    # even over SSH connections or in remote tmux sessions
    #
    # The input is base64-encoded and sent using the OSC 52 protocol:
    # - \033]52   - OSC 52 escape sequence start  
    # - c;        - clipboard selection (c = clipboard, p = primary)
    # - <base64>  - base64-encoded text to copy
    # - \007      - sequence terminator (BEL character)
    #
    # Usage examples:
    #   echo "Hello, World!" | yank              # Copy text to clipboard
    #   cat file.txt | yank                      # Copy file contents
    #   ls -la | yank                            # Copy command output
    #   echo -n "no newline" | yank              # Copy without trailing newline
    #   git diff | yank                          # Copy git diff output
    #
    # Why use this?
    # - Works over SSH: Unlike pbcopy/xclip, this works in remote sessions
    # - Terminal agnostic: Works in any terminal that supports OSC 52
    # - Tmux compatible: Works inside tmux sessions (if tmux allows OSC 52)
    # - No X11 forwarding needed: Doesn't require X11 forwarding for remote clipboard
    #
    # Terminal support:
    # - iTerm2: Enabled by default
    # - Terminal.app: Requires enabling in settings
    # - Alacritty: Enabled by default  
    # - Windows Terminal: Enabled by default
    # - kitty: Enabled by default
    # - GNOME Terminal: Limited support
    #
    # Note: Some terminals limit clipboard size (typically 100KB)
    # For tmux, you may need: set -g set-clipboard on
    
    base64 -w0 | xargs -0 printf "\033]52;c;%s\007"
end
