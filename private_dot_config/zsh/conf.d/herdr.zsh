# herdr passes OSC 8 links and kitty graphics (Unicode placeholders) through, but
# tools that detect support by TERM_PROGRAM or by probing the terminal do not
# recognise it. Force both on inside herdr.
if [[ -n $HERDR_ENV ]]; then
    export FORCE_HYPERLINK=1                  # supports-hyperlinks (Claude Code, other Node CLIs)
    export CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1 # Claude Code images (herdr ignores its graphics probe)
fi
