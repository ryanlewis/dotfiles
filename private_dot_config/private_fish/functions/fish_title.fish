# Custom window/tab title
# This overrides iTerm2's automatic process detection which can show
# misleading names like "Python" when child processes are running
function fish_title
    # If a command is running, show it (argument passed by Fish)
    if set -q argv[1]
        set cmd (string split ' ' -- $argv[1])[1]
        # Simplify common commands
        switch $cmd
            case 'ssh'
                echo "ssh: "(string split ' ' -- $argv[1])[2]
            case 'vim' 'nvim'
                echo "vim: "(basename $PWD)
            case 'claude'
                echo "claude: "(basename $PWD)
            case '*'
                echo $cmd": "(basename $PWD)
        end
    else
        # At prompt - show directory
        echo (basename $PWD)
    end
end
