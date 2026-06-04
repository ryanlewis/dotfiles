# Show TLDR of all available commands and tools
tools() {
    local C_brred=$'\e[91m' C_blue=$'\e[34m' C_brblue=$'\e[94m' C_green=$'\e[32m' \
          C_brgreen=$'\e[92m' C_magenta=$'\e[35m' C_brmagenta=$'\e[95m' C_cyan=$'\e[36m' \
          C_brcyan=$'\e[96m' C_yellow=$'\e[33m' C_bryellow=$'\e[93m' C_red=$'\e[31m' \
          C_white=$'\e[37m' C_brwhite=$'\e[97m' C_brblack=$'\e[90m' C_reset=$'\e[0m'

    # Parse arguments.
    local interactive=false table_mode=false arg
    for arg in "$@"; do
        case $arg in
            --interactive|-i) interactive=true ;;
            --table|-t)       table_mode=true ;;
            --help|-h)
                echo "Usage: tools [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --interactive, -i    Interactive search mode with gum filter"
                echo "  --table, -t          Display in table format"
                echo "  --help, -h           Show this help message"
                return 0
                ;;
        esac
    done

    # All tools: "Category:emoji cmd:Description"
    local -a tools_data=(
        "Core:🏠 chezmoi:Dotfiles manager"
        "Core:🐠 fish:Modern shell with autosuggestions"
        "Core:📦 mise:Version manager for Node/Python/Go"
        "Replace:📂 eza → ls:Lists with icons and git info"
        "Replace:🦇 bat → cat:Syntax highlighting and line numbers"
        "Replace:🔍 fd → find:Simple, fast file finder"
        "Replace:⚡ rg → grep:Ripgrep - blazing fast search"
        "Replace:🚀 z → cd:Smart directory jumper (zoxide)"
        "Replace:📊 btop → top:Beautiful system monitor"
        "Replace:💾 duf → df:User-friendly disk usage"
        "Replace:📈 dust → du:Intuitive disk analyzer"
        "Custom:📁 mkcd:Make directory and enter it"
        "Custom:💾 backup:Create timestamped backups"
        "Custom:📦 extract:Extract any archive format"
        "Custom:🔄 update:Update system packages"
        "Custom:🌐 ports:Show listening network ports"
        "Custom:🌍 myip:Show IP addresses (local/public)"
        "Custom:📋 yank:Copy to clipboard (works over SSH!)"
        "Custom:⚙️  dotfiles:Manage dotfiles easily"
        "Custom:🛠️  tools:Show this command reference"
        "FZF:📂 fcd:Fuzzy change directory"
        "FZF:📄 fopen:Fuzzy open files in editor"
        "FZF:💀 fkill:Fuzzy kill processes"
        "FZF:🔎 fgrep:Fuzzy grep with preview"
        "FZF:🌿 fgit:Interactive git operations"
        "Dev:🎯 lg:Lazygit - git TUI"
        "Dev:🔀 delta:Beautiful git diffs"
        "Dev:🐙 gh:GitHub CLI"
        "Dev:🌐 https:HTTPie - friendly curl"
        "Dev:🎭 jq:JSON processor"
        "Dev:⚡ just:Modern task runner"
        "Dev:🍬 gum:Pretty shell scripts"
        "Dev:🔐 direnv:Auto-load .envrc files"
        "Dev:🌳 broot:Interactive tree navigation"
        "Dev:📖 tldr:Simplified man pages"
        "Dev:✨ starship:Customizable prompt"
        "Dev:📜 atuin:Better shell history (Ctrl+R)"
        "Dev:🌳 wt:Worktrunk - git worktree manager"
        "Dev:☸️  kubectl:Kubernetes CLI"
        "Dev:🔄 kubectx:Switch K8s contexts"
        "Dev:📦 kubens:Switch K8s namespaces"
        "Tmux:🖥️  ta:Tmux session manager"
        "Tmux:🤖 ca:Spawn Claude agents in worktrees"
    )

    local item
    local -a parts

    # ── Interactive mode (gum filter) ─────────────────────────
    if [[ $interactive == true ]]; then
        echo "🔍 Search for a tool (type to filter, enter to select):"
        echo ""
        local -a search_items
        for item in $tools_data; do
            parts=( ${(s.:.)item} )
            search_items+=( "${parts[2]%% *} - ${parts[3]}" )
        done
        local selected
        selected=$(printf "%s\n" "${search_items[@]}" | gum filter --placeholder "Type to search...")
        if [[ -n $selected ]]; then
            echo ""
            print -r -- "Selected: ${C_yellow}${selected}${C_reset}"
        fi
        return 0
    fi

    # ── Table mode (gum table --print) ────────────────────────
    if [[ $table_mode == true ]]; then
        echo "🛠️  Available Tools & Commands 🛠️" | gum style \
            --foreground "#FF6B6B" --bold --align center --width 60 \
            --margin "1 0" --padding "1 2" --border double
        echo ""

        local category cmd desc cmd_with_emoji
        local -a categories=(Core Replace Custom FZF Dev Tmux) csv_lines
        for category in $categories; do
            case $category in
                Core)    print -r -- "${C_blue}━━━ 🏠 Core Commands ━━━${C_reset}" ;;
                Replace) print -r -- "${C_green}━━━ 🔄 Modern CLI Replacements ━━━${C_reset}" ;;
                Custom)  print -r -- "${C_magenta}━━━ ⚡ Custom Functions ━━━${C_reset}" ;;
                FZF)     print -r -- "${C_cyan}━━━ 🔍 FZF-Powered Tools ━━━${C_reset}" ;;
                Dev)     print -r -- "${C_yellow}━━━ 🚀 Development Tools ━━━${C_reset}" ;;
                Tmux)    print -r -- "${C_white}━━━ 🖥️  Tmux Helper ━━━${C_reset}" ;;
            esac

            csv_lines=("Command,Description")
            for item in $tools_data; do
                parts=( ${(s.:.)item} )
                if [[ ${parts[1]} == $category ]]; then
                    cmd_with_emoji=${parts[2]}
                    cmd=${cmd_with_emoji#* }       # strip leading emoji + space
                    desc=${parts[3]}
                    [[ $category != Replace ]] && cmd=${cmd%% → *}
                    if [[ $desc == *,* ]]; then
                        csv_lines+=( "$cmd,\"$desc\"" )
                    else
                        csv_lines+=( "$cmd,$desc" )
                    fi
                fi
            done
            printf "%s\n" "${csv_lines[@]}" | gum table --print
            echo ""
        done

        print -r -- "${C_brblack}💡 Tip: Use 'tools --interactive' for search mode${C_reset}"
        return 0
    fi

    # ── Default colourful output, paged through bat ───────────
    {
        print
        print -r -- "${C_brred}╔═══════════════════════════════════════════════╗${C_reset}"
        print -r -- "${C_brred}║      🛠️   Available Tools & Commands  🛠️      ║${C_reset}"
        print -r -- "${C_brred}╚═══════════════════════════════════════════════╝${C_reset}"
        print

        print -r -- "${C_blue}━━━ 🏠 Core Commands ━━━${C_reset}"
        print -r -- "${C_brblue}• chezmoi${C_reset} - Dotfiles manager"
        print -r -- "${C_brblue}• fish${C_reset}    - Modern shell with autosuggestions"
        print -r -- "${C_brblue}• mise${C_reset}    - Version manager for Node/Python/Go"
        print

        print -r -- "${C_green}━━━ 🔄 Modern CLI Replacements ━━━${C_reset}"
        print -r -- "${C_brgreen}• eza${C_reset}  → ls   ${C_brblack}(with icons, git info)${C_reset}"
        print -r -- "${C_brgreen}• bat${C_reset}  → cat  ${C_brblack}(syntax highlighting)${C_reset}"
        print -r -- "${C_brgreen}• fd${C_reset}   → find ${C_brblack}(simpler, faster)${C_reset}"
        print -r -- "${C_brgreen}• rg${C_reset}   → grep ${C_brblack}(ripgrep, super fast)${C_reset}"
        print -r -- "${C_brgreen}• z${C_reset}    → cd   ${C_brblack}(zoxide, learns your dirs)${C_reset}"
        print -r -- "${C_brgreen}• btop${C_reset} → top  ${C_brblack}(beautiful UI)${C_reset}"
        print -r -- "${C_brgreen}• duf${C_reset}  → df   ${C_brblack}(friendly disk usage)${C_reset}"
        print -r -- "${C_brgreen}• dust${C_reset} → du   ${C_brblack}(intuitive disk analyzer)${C_reset}"
        print

        print -r -- "${C_magenta}━━━ ⚡ Custom Functions ━━━${C_reset}"
        print -r -- "${C_brmagenta}• mkcd${C_reset}    - Make dir and enter it"
        print -r -- "${C_brmagenta}• backup${C_reset}  - Timestamp backup files"
        print -r -- "${C_brmagenta}• extract${C_reset} - Extract any archive"
        print -r -- "${C_brmagenta}• update${C_reset}  - Update system packages"
        print -r -- "${C_brmagenta}• ports${C_reset}   - Show listening ports"
        print -r -- "${C_brmagenta}• myip${C_reset}    - Show IP addresses"
        print -r -- "${C_brmagenta}• yank${C_reset}    - Copy to clipboard ${C_yellow}(works over SSH!)${C_reset}"
        print -r -- "${C_brmagenta}• dotfiles${C_reset} - Manage dotfiles easily"
        print -r -- "${C_brmagenta}• tools${C_reset}   - Show this help"
        print

        print -r -- "${C_cyan}━━━ 🔍 FZF-Powered (fuzzy search) ━━━${C_reset}"
        print -r -- "${C_brcyan}• fcd${C_reset}   - Fuzzy change directory"
        print -r -- "${C_brcyan}• fopen${C_reset} - Fuzzy open files"
        print -r -- "${C_brcyan}• fkill${C_reset} - Fuzzy kill processes"
        print -r -- "${C_brcyan}• fgrep${C_reset} - Fuzzy grep with preview"
        print -r -- "${C_brcyan}• fgit${C_reset}  - Interactive git operations"
        print

        print -r -- "${C_yellow}━━━ 🚀 Development Tools ━━━${C_reset}"
        print -r -- "${C_bryellow}• lg${C_reset}       - Lazygit (git TUI)"
        print -r -- "${C_bryellow}• delta${C_reset}    - Better git diffs"
        print -r -- "${C_bryellow}• gh${C_reset}       - GitHub CLI"
        print -r -- "${C_bryellow}• https${C_reset}    - HTTPie (friendly curl)"
        print -r -- "${C_bryellow}• jq${C_reset}       - JSON processor"
        print -r -- "${C_bryellow}• just${C_reset}     - Modern make"
        print -r -- "${C_bryellow}• gum${C_reset}      - Pretty shell scripts"
        print -r -- "${C_bryellow}• direnv${C_reset}   - Auto-load .envrc"
        print -r -- "${C_bryellow}• broot${C_reset}    - Better tree"
        print -r -- "${C_bryellow}• tldr${C_reset}     - Simple man pages"
        print -r -- "${C_bryellow}• starship${C_reset} - Pretty prompt"
        print -r -- "${C_bryellow}• atuin${C_reset}    - Better shell history"
        print -r -- "${C_bryellow}• wt${C_reset}       - Git worktree manager"
        print

        print -r -- "${C_red}━━━ ☸️  Kubernetes Tools ━━━${C_reset}"
        print -r -- "${C_brred}• kubectl${C_reset}  - Kubernetes CLI"
        print -r -- "${C_brred}• kubectx${C_reset} - Switch contexts easily"
        print -r -- "${C_brred}• kubens${C_reset}  - Switch namespaces"
        print

        print -r -- "${C_white}━━━ 🖥️  Tmux Helper ━━━${C_reset}"
        print -r -- "${C_brwhite}• ta${C_reset} - Tmux session manager ${C_brblack}(attach/create)${C_reset}"
        print -r -- "${C_brwhite}• ca${C_reset} - Spawn Claude agents in worktrees"
        print

        print -r -- "${C_brblack}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_reset}"
        print -r -- "${C_brblack}💡 Tips:${C_reset}"
        print -r -- "${C_brblack}  • Use 'tools --interactive' for search mode${C_reset}"
        print -r -- "${C_brblack}  • Use 'tools --table' for table view${C_reset}"
        print -r -- "${C_brblack}  • Most commands have --help flags${C_reset}"
    } | bat --style=plain --paging=always
}
