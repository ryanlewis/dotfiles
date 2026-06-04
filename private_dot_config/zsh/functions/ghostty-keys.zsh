# Show Ghostty keybindings reference (parsed from ~/.config/ghostty/config)
ghostty-keys() {
    emulate -L zsh
    setopt local_options extended_glob

    local config=~/.config/ghostty/config
    if [[ ! -f $config ]]; then
        echo "Ghostty config not found at $config"
        return 1
    fi

    local C_brred=$'\e[91m' C_brwhite=$'\e[97m' C_brblack=$'\e[90m' C_reset=$'\e[0m'

    # ── helpers ──────────────────────────────────────────────
    # Format a raw key token into a human-readable label.
    __gk_fmt_key() {
        case $1 in
            cmd)          echo "Cmd" ;;
            alt)          echo "Opt" ;;
            ctrl)         echo "Ctrl" ;;
            shift)        echo "Shift" ;;
            left)         echo "←" ;;
            right)        echo "→" ;;
            up)           echo "↑" ;;
            down)         echo "↓" ;;
            return)       echo "Return" ;;
            grave_accent) echo '`' ;;
            page_up)      echo "PgUp" ;;
            page_down)    echo "PgDn" ;;
            *)            echo "${(U)1}" ;;
        esac
    }

    # Format a raw action into a readable description.
    __gk_fmt_action() {
        case $1 in
            toggle_quick_terminal) echo "Toggle quick terminal" ;;
            new_split:right)       echo "Split right" ;;
            new_split:down)        echo "Split down" ;;
            goto_split:left)       echo "Focus split left" ;;
            goto_split:right)      echo "Focus split right" ;;
            goto_split:top)        echo "Focus split up" ;;
            goto_split:bottom)     echo "Focus split down" ;;
            resize_split:left*)    echo "Resize split ←" ;;
            resize_split:right*)   echo "Resize split →" ;;
            resize_split:up*)      echo "Resize split ↑" ;;
            resize_split:down*)    echo "Resize split ↓" ;;
            toggle_split_zoom)     echo "Zoom / unzoom split" ;;
            equalize_splits)       echo "Equalise splits" ;;
            jump_to_prompt:-1)     echo "Previous prompt" ;;
            jump_to_prompt:1)      echo "Next prompt" ;;
            new_tab)               echo "New tab" ;;
            close_surface)         echo "Close tab / split" ;;
            previous_tab)          echo "Previous tab" ;;
            next_tab)              echo "Next tab" ;;
            *)
                # Fallback: humanise underscores/colons, capitalise first letter.
                local s=${1//_/ }
                s=${s//:/ }
                echo "${(U)s[1]}${s[2,-1]}"
                ;;
        esac
    }

    # Section comment → colour escape.
    __gk_section_color() {
        case $1 in
            "Quick Terminal"*)    echo $'\e[36m' ;;  # cyan
            "Split Panes"*)       echo $'\e[32m' ;;  # green
            "Prompt Navigation"*) echo $'\e[35m' ;;  # magenta
            "Tabs"*)              echo $'\e[33m' ;;  # yellow
            *)                    echo $'\e[34m' ;;  # blue
        esac
    }

    # ── parse config & render ────────────────────────────────
    {
        print
        print -r -- "${C_brred}╔══════════════════════════════════════════════════╗${C_reset}"
        print -r -- "${C_brred}║          Ghostty Keybindings Reference           ║${C_reset}"
        print -r -- "${C_brred}╚══════════════════════════════════════════════════╝${C_reset}"

        local current_section="" line binding raw_keys raw_action global_suffix key_str action_str clr k
        local -a printed_sections formatted

        while IFS= read -r line; do
            # Detect section headers: "# ── Name ──…"
            if [[ $line =~ '^[[:space:]]*#[[:space:]]*──' ]]; then
                current_section=${line##*── }
                current_section=${current_section%% ─*}
                current_section=${current_section##[[:space:]]##}
                current_section=${current_section%%[[:space:]]##}
            fi

            # Only process keybind lines.
            [[ $line =~ '^[[:space:]]*keybind[[:space:]]*=' ]] || continue

            # Print section header on first keybind in a new section.
            if (( ! ${printed_sections[(Ie)$current_section]} )); then
                clr=$(__gk_section_color "$current_section")
                print
                print -r -- "  ${clr}━━━ $current_section ━━━${C_reset}"
                printed_sections+=("$current_section")
            fi

            # Extract "keys=action" from the line.
            binding=${line##[[:space:]]#keybind[[:space:]]#=[[:space:]]#}
            raw_keys=${binding%%=*}
            raw_action=${binding#*=}

            # Handle global prefix.
            global_suffix=""
            if [[ $raw_keys == global:* ]]; then
                global_suffix=" (global)"
                raw_keys=${raw_keys#global:}
            fi

            # Build formatted key string.
            formatted=()
            for k in ${(s.+.)raw_keys}; do
                formatted+=( "$(__gk_fmt_key "$k")" )
            done
            key_str="${(j. + .)formatted}$global_suffix"

            # Build action description.
            action_str=$(__gk_fmt_action "$raw_action")

            printf "    ${C_brwhite}%-30s${C_reset} %s\n" "$key_str" "$action_str"
        done < $config

        # ── Built-in Defaults ────────────────────────────────
        print
        print -r -- "  ${C_brblack}━━━ Built-in Defaults ━━━${C_reset}"

        local item
        local -a defaults=(
            "Cmd + N|New window"
            "Cmd + ,|Open config"
            "Cmd + Shift + ,|Reload config"
            "Cmd + C|Copy"
            "Cmd + V|Paste"
            "Cmd + +|Increase font size"
            "Cmd + -|Decrease font size"
            "Cmd + 0|Reset font size"
            "Cmd + 1-9|Jump to tab N"
            "Cmd + Enter|Toggle fullscreen"
        )
        for item in $defaults; do
            local -a parts
            parts=( ${(s.|.)item} )
            printf "    ${C_brblack}%-30s${C_reset} %s\n" "${parts[1]}" "${parts[2]}"
        done

        print
        print -r -- "  ${C_brblack}Source: $config${C_reset}"
        print
    } | if command -v bat >/dev/null; then
        bat --style=plain --paging=always
    else
        cat
    fi

    # Clean up helper functions.
    unset -f __gk_fmt_key __gk_fmt_action __gk_section_color
}
