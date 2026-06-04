# Show tmux keybindings reference
tmux-keys() {
    local C_white=$'\e[97m' C_reset=$'\e[0m' C_cyan=$'\e[36m' C_green=$'\e[32m' \
          C_magenta=$'\e[35m' C_yellow=$'\e[33m' C_brred=$'\e[91m' C_brblack=$'\e[90m'

    # Helper: print a key/description pair (split on "::").
    _tk_row() {
        local -a parts
        parts=( ${(s.::.)1} )
        printf "    ${C_white}%-30s${C_reset} %s\n" "${parts[1]}" "${parts[2]}"
    }
    # Helper: print a section header.
    _tk_section() {
        print
        print -r -- "  ${1}━━━ ${2} ━━━${C_reset}"
    }

    print
    print -r -- "${C_brred}╔══════════════════════════════════════════════════╗${C_reset}"
    print -r -- "${C_brred}║            tmux Keybindings Reference             ║${C_reset}"
    print -r -- "${C_brred}╚══════════════════════════════════════════════════╝${C_reset}"

    local item
    _tk_section "$C_cyan" "Prefixless — Alt+Shift"
    for item in \
        "Alt + Shift + H / J / K / L::Focus pane ← ↓ ↑ →" \
        "Alt + Shift + [::Previous window" \
        "Alt + Shift + ]::Next window"; do
        _tk_row "$item"
    done

    _tk_section "$C_cyan" "Prefixless — Ctrl+Alt"
    for item in \
        "Ctrl + Alt + H / ←::Focus pane left" \
        "Ctrl + Alt + J / ↓::Focus pane down" \
        "Ctrl + Alt + K / ↑::Focus pane up" \
        "Ctrl + Alt + L / →::Focus pane right" \
        "Ctrl + Alt + P::Previous window" \
        "Ctrl + Alt + N::Next window" \
        "Ctrl + Alt + C::New window (inherits path)" \
        "Ctrl + Alt + 1-9::Jump to window N" \
        "Ctrl + Alt + Z::Toggle pane zoom" \
        "Ctrl + Alt + S::Session picker" \
        "Ctrl + Alt + G::Popup terminal"; do
        _tk_row "$item"
    done

    _tk_section "$C_green" "Prefix — Ctrl+A, then…"
    for item in \
        "H / J / K / L::Focus pane ← ↓ ↑ →" \
        "Shift + H / J / K / L::Resize pane (repeatable)" \
        "|::Split right (inherits path)" \
        "-::Split down (inherits path)" \
        "R::Reload config"; do
        _tk_row "$item"
    done

    _tk_section "$C_magenta" "Copy Mode (vi)"
    for item in \
        "Prefix, then [::Enter copy mode" \
        "V::Begin selection" \
        "Y::Yank (copy + exit)" \
        "R::Toggle rectangle selection"; do
        _tk_row "$item"
    done

    _tk_section "$C_yellow" "General"
    for item in \
        "Prefix::Ctrl + A" \
        "Mouse::Enabled" \
        "Base index::1 (windows and panes)" \
        "Scrollback::50,000 lines" \
        "Escape time::0ms"; do
        _tk_row "$item"
    done

    print
    print -r -- "  ${C_brblack}Source: ~/.tmux.conf (chezmoi managed)${C_reset}"
    print

    unset -f _tk_row _tk_section
}
