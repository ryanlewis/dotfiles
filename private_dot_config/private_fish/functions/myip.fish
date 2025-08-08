function myip --description "Get IP addresses"
    echo "Local IP addresses:"
    if command -v ip > /dev/null
        # Linux with ip command
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
    else if command -v ifconfig > /dev/null
        # macOS and older systems
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    end
    
    echo ""
    echo "Public IP address:"
    if command -v curl > /dev/null
        curl -s https://api.ipify.org
        echo ""
    else if command -v wget > /dev/null
        wget -qO- https://api.ipify.org
        echo ""
    end
end