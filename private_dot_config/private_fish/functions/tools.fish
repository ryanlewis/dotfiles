function tools --description "Show TLDR of all available commands and tools"
    # Parse arguments
    set -l interactive false
    set -l table_mode false
    
    for arg in $argv
        switch $arg
            case --interactive -i
                set interactive true
            case --table -t
                set table_mode true
            case --help -h
                echo "Usage: tools [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --interactive, -i    Interactive search mode with gum filter"
                echo "  --table, -t         Display in table format"
                echo "  --help, -h          Show this help message"
                return 0
        end
    end
    
    # Define all tools with emojis and categories
    set -l tools_data \
        "Core:🏠 chezmoi:Dotfiles manager" \
        "Core:🐠 fish:Modern shell with autosuggestions" \
        "Core:📦 asdf:Version manager for Node/Python/Go" \
        "Replace:📂 eza → ls:Lists with icons and git info" \
        "Replace:🦇 bat → cat:Syntax highlighting and line numbers" \
        "Replace:🔍 fd → find:Simple, fast file finder" \
        "Replace:⚡ rg → grep:Ripgrep - blazing fast search" \
        "Replace:🚀 z → cd:Smart directory jumper (zoxide)" \
        "Replace:📊 btop → top:Beautiful system monitor" \
        "Replace:💾 duf → df:User-friendly disk usage" \
        "Replace:📈 dust → du:Intuitive disk analyzer" \
        "Custom:📁 mkcd:Make directory and enter it" \
        "Custom:💾 backup:Create timestamped backups" \
        "Custom:📦 extract:Extract any archive format" \
        "Custom:🔄 update:Update system packages" \
        "Custom:🌐 ports:Show listening network ports" \
        "Custom:🌍 myip:Show IP addresses (local/public)" \
        "Custom:📋 yank:Copy to clipboard (works over SSH!)" \
        "Custom:⚙️  dotfiles:Manage dotfiles easily" \
        "Custom:🛠️  tools:Show this command reference" \
        "FZF:📂 fcd:Fuzzy change directory" \
        "FZF:📄 fopen:Fuzzy open files in editor" \
        "FZF:💀 fkill:Fuzzy kill processes" \
        "FZF:🔎 fgrep:Fuzzy grep with preview" \
        "FZF:🌿 fgit:Interactive git operations" \
        "Dev:🎯 lg:Lazygit - git TUI" \
        "Dev:🔀 delta:Beautiful git diffs" \
        "Dev:🐙 gh:GitHub CLI" \
        "Dev:🌐 https:HTTPie - friendly curl" \
        "Dev:🎭 jq:JSON processor" \
        "Dev:⚡ just:Modern task runner" \
        "Dev:🍬 gum:Pretty shell scripts" \
        "Dev:🔐 direnv:Auto-load .envrc files" \
        "Dev:🌳 broot:Interactive tree navigation" \
        "Dev:📖 tldr:Simplified man pages" \
        "Dev:✨ starship:Customizable prompt" \
        "Dev:📜 atuin:Better shell history (Ctrl+R)"
    
    # Interactive mode with gum filter
    if test "$interactive" = "true"
        echo "🔍 Search for a tool (type to filter, enter to select):"
        echo ""
        
        # Create searchable list
        set -l search_items
        for item in $tools_data
            set -l parts (string split ":" $item)
            set -l cmd_desc (string split " " $parts[2] -m 1)
            set search_items $search_items "$cmd_desc[1] - $parts[3]"
        end
        
        # Use gum filter
        set -l selected (printf "%s\n" $search_items | gum filter --placeholder "Type to search...")
        
        if test -n "$selected"
            echo ""
            echo "Selected: "(set_color yellow)"$selected"(set_color normal)
        end
        return 0
    end
    
    # Table mode with gum table --print
    if test "$table_mode" = "true"
        # Header with gum style
        echo "🛠️  Available Tools & Commands 🛠️" | gum style \
            --foreground "#FF6B6B" \
            --bold \
            --align center \
            --width 60 \
            --margin "1 0" \
            --padding "1 2" \
            --border double
        
        echo ""
        
        # Display each category as a table
        set -l categories "Core" "Replace" "Custom" "FZF" "Dev"
        
        for category in $categories
            # Category header with color
            switch $category
                case "Core"
                    echo (set_color blue)"━━━ 🏠 Core Commands ━━━"(set_color normal)
                case "Replace"
                    echo (set_color green)"━━━ 🔄 Modern CLI Replacements ━━━"(set_color normal)
                case "Custom"
                    echo (set_color magenta)"━━━ ⚡ Custom Fish Functions ━━━"(set_color normal)
                case "FZF"
                    echo (set_color cyan)"━━━ 🔍 FZF-Powered Tools ━━━"(set_color normal)
                case "Dev"
                    echo (set_color yellow)"━━━ 🚀 Development Tools ━━━"(set_color normal)
            end
            
            # Build CSV lines for this category
            set -l csv_lines "Command,Description"
            for item in $tools_data
                set -l parts (string split ":" $item)
                if test "$parts[1]" = "$category"
                    # Extract command and description
                    set -l cmd_with_emoji $parts[2]
                    set -l cmd (string replace -r '^[^ ]+ (.+)$' '$1' $cmd_with_emoji)
                    set -l desc $parts[3]
                    
                    # For non-replacements, remove arrow part
                    if test "$category" != "Replace"
                        set cmd (string split " → " $cmd)[1]
                    end
                    
                    # Quote fields if they contain commas
                    if string match -q "*,*" $desc
                        set csv_lines $csv_lines "$cmd,\"$desc\""
                    else
                        set csv_lines $csv_lines "$cmd,$desc"
                    end
                end
            end
            
            # Display table using gum with --print flag
            printf "%s\n" $csv_lines | gum table --print
            echo ""
        end
        
        echo (set_color brblack)"💡 Tip: Use 'tools --interactive' for search mode"(set_color normal)
        return 0
    end
    
    # Default colorful output
    # Fancy header with gum
    echo "
╔══════════════════════════════════════════════╗
║       🛠️   Available Tools & Commands  🛠️       ║
╚══════════════════════════════════════════════╝" | gum style \
        --foreground "#FF6B6B" \
        --bold \
        --align center
    
    echo ""
    
    # Core Commands
    echo (set_color blue)"━━━ 🏠 Core Commands ━━━"(set_color normal)
    echo (set_color brblue)"• chezmoi"(set_color normal)" - Dotfiles manager"
    echo (set_color brblue)"• fish"(set_color normal)"    - Modern shell with autosuggestions"
    echo (set_color brblue)"• asdf"(set_color normal)"    - Version manager for Node/Python/Go"
    echo ""
    
    # Modern CLI Replacements
    echo (set_color green)"━━━ 🔄 Modern CLI Replacements ━━━"(set_color normal)
    echo (set_color brgreen)"• eza"(set_color normal)"  → ls   "(set_color brblack)"(with icons, git info)"(set_color normal)
    echo (set_color brgreen)"• bat"(set_color normal)"  → cat  "(set_color brblack)"(syntax highlighting)"(set_color normal)
    echo (set_color brgreen)"• fd"(set_color normal)"   → find "(set_color brblack)"(simpler, faster)"(set_color normal)
    echo (set_color brgreen)"• rg"(set_color normal)"   → grep "(set_color brblack)"(ripgrep, super fast)"(set_color normal)
    echo (set_color brgreen)"• z"(set_color normal)"    → cd   "(set_color brblack)"(zoxide, learns your dirs)"(set_color normal)
    echo (set_color brgreen)"• btop"(set_color normal)" → top  "(set_color brblack)"(beautiful UI)"(set_color normal)
    echo (set_color brgreen)"• duf"(set_color normal)"  → df   "(set_color brblack)"(friendly disk usage)"(set_color normal)
    echo (set_color brgreen)"• dust"(set_color normal)" → du   "(set_color brblack)"(intuitive disk analyzer)"(set_color normal)
    echo ""
    
    # Custom Fish Functions
    echo (set_color magenta)"━━━ ⚡ Custom Fish Functions ━━━"(set_color normal)
    echo (set_color brmagenta)"• mkcd"(set_color normal)"    - Make dir and enter it"
    echo (set_color brmagenta)"• backup"(set_color normal)"  - Timestamp backup files"
    echo (set_color brmagenta)"• extract"(set_color normal)" - Extract any archive"
    echo (set_color brmagenta)"• update"(set_color normal)"  - Update system packages"
    echo (set_color brmagenta)"• ports"(set_color normal)"   - Show listening ports"
    echo (set_color brmagenta)"• myip"(set_color normal)"    - Show IP addresses"
    echo (set_color brmagenta)"• yank"(set_color normal)"    - Copy to clipboard "(set_color yellow)"(works over SSH!)"(set_color normal)
    echo (set_color brmagenta)"• dotfiles"(set_color normal)" - Manage dotfiles easily"
    echo (set_color brmagenta)"• tools"(set_color normal)"   - Show this help"
    echo ""
    
    # FZF-Powered
    echo (set_color cyan)"━━━ 🔍 FZF-Powered (fuzzy search) ━━━"(set_color normal)
    echo (set_color brcyan)"• fcd"(set_color normal)"   - Fuzzy change directory"
    echo (set_color brcyan)"• fopen"(set_color normal)" - Fuzzy open files"
    echo (set_color brcyan)"• fkill"(set_color normal)" - Fuzzy kill processes"
    echo (set_color brcyan)"• fgrep"(set_color normal)" - Fuzzy grep with preview"
    echo (set_color brcyan)"• fgit"(set_color normal)"  - Interactive git operations"
    echo ""
    
    # Dev Tools
    echo (set_color yellow)"━━━ 🚀 Development Tools ━━━"(set_color normal)
    echo (set_color bryellow)"• lg"(set_color normal)"       - Lazygit (git TUI)"
    echo (set_color bryellow)"• delta"(set_color normal)"    - Better git diffs"
    echo (set_color bryellow)"• gh"(set_color normal)"       - GitHub CLI"
    echo (set_color bryellow)"• https"(set_color normal)"    - HTTPie (friendly curl)"
    echo (set_color bryellow)"• jq"(set_color normal)"       - JSON processor"
    echo (set_color bryellow)"• just"(set_color normal)"     - Modern make"
    echo (set_color bryellow)"• gum"(set_color normal)"      - Pretty shell scripts"
    echo (set_color bryellow)"• direnv"(set_color normal)"   - Auto-load .envrc"
    echo (set_color bryellow)"• broot"(set_color normal)"    - Better tree"
    echo (set_color bryellow)"• tldr"(set_color normal)"     - Simple man pages"
    echo (set_color bryellow)"• starship"(set_color normal)" - Pretty prompt"
    echo (set_color bryellow)"• atuin"(set_color normal)"    - Better shell history"
    echo ""
    
    # Footer tips
    echo (set_color brblack)"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"(set_color normal)
    echo (set_color brblack)"💡 Tips:"(set_color normal)
    echo (set_color brblack)"  • Use 'tools --interactive' for search mode"(set_color normal)
    echo (set_color brblack)"  • Use 'tools --table' for table view"(set_color normal)
    echo (set_color brblack)"  • Most commands have --help flags"(set_color normal)
end