function ports --description "Show listening ports"
    if type -q lsof
        # macOS and systems with lsof
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    else if type -q ss
        # Modern Linux with ss
        sudo ss -tulpn | grep LISTEN
    else if type -q netstat
        # Fallback to netstat
        sudo netstat -tulpn | grep LISTEN
    else
        echo "No suitable command found to list ports"
        return 1
    end
end