function fish_user_key_bindings
    # Custom key bindings for Fish shell with vi mode
    
    # Ctrl+Space: Accept autosuggestion in insert mode
    bind -M insert ctrl-space accept-autosuggestion
    
    # Ctrl+P: Previous command (up-or-search) in insert mode
    bind -M insert ctrl-p up-or-search
    
    # Ctrl+N: Next command (down-or-search) in insert mode
    bind -M insert ctrl-n down-or-search
    
    # Ctrl+_ (Shift+Tab): Claude Code planning mode compatibility
    # Special mapping for Terminus iPhone app
    bind -M insert ctrl-_ 'commandline -f repaint; and stty raw -echo; and printf "\033[Z"; and stty -raw echo'
end