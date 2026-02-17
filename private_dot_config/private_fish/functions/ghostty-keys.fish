function ghostty-keys --description "Show Ghostty keybindings reference"
    set -l config ~/.config/ghostty/config

    if not test -f $config
        echo "Ghostty config not found at $config"
        return 1
    end

    # ── helpers ──────────────────────────────────────────────
    # Format a raw key token into a human-readable label
    function __gk_fmt_key
        switch $argv[1]
            case cmd;           echo Cmd
            case alt;           echo Opt
            case ctrl;          echo Ctrl
            case shift;         echo Shift
            case left;          echo "←"
            case right;         echo "→"
            case up;            echo "↑"
            case down;          echo "↓"
            case return;        echo Return
            case grave_accent;  echo "\`"
            case page_up;       echo PgUp
            case page_down;     echo PgDn
            case '*';           echo (string upper $argv[1])
        end
    end

    # Format a raw action into a readable description
    function __gk_fmt_action
        switch $argv[1]
            case toggle_quick_terminal;  echo "Toggle quick terminal"
            case "new_split:right";      echo "Split right"
            case "new_split:down";       echo "Split down"
            case "goto_split:left";      echo "Focus split left"
            case "goto_split:right";     echo "Focus split right"
            case "goto_split:top";       echo "Focus split up"
            case "goto_split:bottom";    echo "Focus split down"
            case "resize_split:left*";   echo "Resize split ←"
            case "resize_split:right*";  echo "Resize split →"
            case "resize_split:up*";     echo "Resize split ↑"
            case "resize_split:down*";   echo "Resize split ↓"
            case toggle_split_zoom;      echo "Zoom / unzoom split"
            case equalize_splits;        echo "Equalise splits"
            case "jump_to_prompt:-1";    echo "Previous prompt"
            case "jump_to_prompt:1";     echo "Next prompt"
            case new_tab;                echo "New tab"
            case close_surface;          echo "Close tab / split"
            case previous_tab;           echo "Previous tab"
            case next_tab;               echo "Next tab"
            case '*'
                # Fallback: humanise underscores/colons
                set -l s (string replace -a "_" " " $argv[1])
                set -l s (string replace -a ":" " " $s)
                echo (string sub -l 1 $s | string upper)(string sub -s 2 $s)
        end
    end

    # Section comment → colour mapping
    function __gk_section_color
        switch $argv[1]
            case "Quick Terminal*";      echo cyan
            case "Split Panes*";         echo green
            case "Prompt Navigation*";   echo magenta
            case "Tabs*";               echo yellow
            case '*';                    echo blue
        end
    end

    # ── parse config & render ────────────────────────────────
    begin
        echo ""
        echo (set_color brred)"╔══════════════════════════════════════════════════╗"(set_color normal)
        echo (set_color brred)"║          Ghostty Keybindings Reference          ║"(set_color normal)
        echo (set_color brred)"╚══════════════════════════════════════════════════╝"(set_color normal)

        set -l current_section ""
        set -l printed_sections

        while read -l line
            # Detect section headers: "# ── Name ──…"
            if string match -qr '^\s*#\s*──\s+(.+?)\s+─' -- $line
                set current_section (string match -r '^\s*#\s*──\s+(.+?)\s+─' -- $line)[2]
                set current_section (string trim $current_section)
            end

            # Only process keybind lines
            string match -qr '^\s*keybind\s*=' -- $line; or continue

            # Print section header on first keybind in a new section
            if not contains "$current_section" $printed_sections
                set -l clr (__gk_section_color "$current_section")
                echo ""
                echo "  "(set_color $clr)"━━━ $current_section ━━━"(set_color normal)
                set -a printed_sections "$current_section"
            end

            # Extract "keys=action" from the line
            set -l binding (string replace -r '^\s*keybind\s*=\s*' '' $line)
            set -l parts (string split -m 1 "=" $binding)
            set -l raw_keys $parts[1]
            set -l raw_action $parts[2]

            # Handle global prefix
            set -l global_suffix ""
            if string match -q "global:*" $raw_keys
                set global_suffix " (global)"
                set raw_keys (string replace "global:" "" $raw_keys)
            end

            # Build formatted key string
            set -l formatted
            for k in (string split "+" $raw_keys)
                set -a formatted (__gk_fmt_key $k)
            end
            set -l key_str (string join " + " $formatted)$global_suffix

            # Build action description
            set -l action_str (__gk_fmt_action $raw_action)

            # Print with alignment
            set -l padded (printf "%-30s" "$key_str")
            echo "    "(set_color brwhite)"$padded"(set_color normal)" $action_str"
        end <$config

        # ── Built-in Defaults ────────────────────────────────
        echo ""
        echo "  "(set_color brblack)"━━━ Built-in Defaults ━━━"(set_color normal)

        set -l defaults \
            "Cmd + N|New window" \
            "Cmd + ,|Open config" \
            "Cmd + Shift + ,|Reload config" \
            "Cmd + C|Copy" \
            "Cmd + V|Paste" \
            "Cmd + +|Increase font size" \
            "Cmd + -|Decrease font size" \
            "Cmd + 0|Reset font size" \
            "Cmd + 1-9|Jump to tab N" \
            "Cmd + Enter|Toggle fullscreen"

        for item in $defaults
            set -l parts (string split "|" $item)
            set -l padded (printf "%-30s" "$parts[1]")
            echo "    "(set_color brblack)"$padded"(set_color normal)" $parts[2]"
        end

        echo ""
        echo "  "(set_color brblack)"Source: $config"(set_color normal)
        echo ""
    end | if type -q bat
        bat --style=plain --paging=always
    else
        cat
    end

    # Clean up helper functions
    functions -e __gk_fmt_key __gk_fmt_action __gk_section_color
end
