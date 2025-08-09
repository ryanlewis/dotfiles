function tools --description "Show TLDR of all available commands and tools"
    echo "
## Core Commands
• chezmoi - Dotfiles manager
• fish    - Modern shell
• asdf    - Version manager for Node/Python/Go

## Modern CLI Replacements
• eza  → ls   (with icons, git info)
• bat  → cat  (syntax highlighting)
• fd   → find (simpler, faster)
• rg   → grep (ripgrep, super fast)
• z    → cd   (zoxide, learns your dirs)
• btop → top  (beautiful UI)
• duf  → df   (friendly disk usage)
• dust → du   (intuitive disk analyzer)

## Custom Fish Functions
• mkcd    - Make dir and enter it
• backup  - Timestamp backup files
• extract - Extract any archive
• update  - Update system packages
• ports   - Show listening ports
• myip    - Show IP addresses
• yank    - Copy to clipboard (works over SSH!)
• dotfiles - Manage dotfiles easily
• tools   - Show this help

## FZF-Powered (fuzzy search)
• fcd   - Fuzzy change directory
• fopen - Fuzzy open files
• fkill - Fuzzy kill processes
• fgrep - Fuzzy grep with preview
• fgit  - Interactive git operations

## Dev Tools
• lg       - lazygit (git TUI)
• delta    - Better git diffs
• gh       - GitHub CLI
• https    - httpie (friendly curl)
• jq       - JSON processor
• just     - Modern make
• gum      - Pretty shell scripts
• direnv   - Auto-load .envrc
• broot    - Better tree
• tldr     - Simple man pages
• starship - Pretty prompt
• atuin    - Better shell history
"
end