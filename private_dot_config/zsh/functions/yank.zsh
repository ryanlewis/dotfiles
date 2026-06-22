# Copy text to clipboard via OSC 52 escape sequence (works over SSH)
#
# Uses the OSC 52 escape sequence to copy stdin to the clipboard. This works in
# terminals that support OSC 52, including over SSH.
#
# Usage:
#   echo "Hello, World!" | yank
#   cat file.txt | yank
#   git diff | yank
#
# Note: `base64 -w0` requires GNU coreutils (provided on macOS via the brew
# coreutils gnubin path, which is prepended to PATH on macOS).
yank() {
    base64 -w0 | xargs -0 printf "\033]52;c;%s\007"
}
