function tmux-keys --description "Show tmux keybindings reference"
    # Helper: print a key/description pair
    function __tk_row
        set -l parts (string split -m 1 -- "::" $argv[1])
        set -l padded (printf "%-30s" "$parts[1]")
        echo "    "(set_color brwhite)"$padded"(set_color normal)" $parts[2]"
    end

    # Helper: print a section header
    function __tk_section
        echo ""
        echo "  "(set_color $argv[1])"━━━ $argv[2] ━━━"(set_color normal)
    end

    begin
        echo ""
        echo (set_color brred)"╔══════════════════════════════════════════════════╗"(set_color normal)
        echo (set_color brred)"║            tmux Keybindings Reference             ║"(set_color normal)
        echo (set_color brred)"╚══════════════════════════════════════════════════╝"(set_color normal)

        __tk_section cyan "Prefixless — Ctrl+Alt"

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
            "Ctrl + Alt + G::Popup terminal"
            __tk_row $item
        end

        __tk_section green "Prefix — Ctrl+A, then…"

        for item in \
            "H / J / K / L::Focus pane ← ↓ ↑ →" \
            "Shift + H / J / K / L::Resize pane (repeatable)" \
            "|::Split right (inherits path)" \
            "-::Split down (inherits path)" \
            "R::Reload config"
            __tk_row $item
        end

        __tk_section magenta "Copy Mode (vi)"

        for item in \
            "Prefix, then [::Enter copy mode" \
            "V::Begin selection" \
            "Y::Yank (copy + exit)" \
            "R::Toggle rectangle selection"
            __tk_row $item
        end

        __tk_section yellow "General"

        for item in \
            "Prefix::Ctrl + A" \
            "Mouse::Enabled" \
            "Base index::1 (windows and panes)" \
            "Scrollback::50,000 lines" \
            "Escape time::0ms"
            __tk_row $item
        end

        echo ""
        echo "  "(set_color brblack)"Source: ~/.tmux.conf (chezmoi managed)"(set_color normal)
        echo ""
    end

    functions -e __tk_row __tk_section
end
