# Get IP addresses (local + public)
myip() {
    echo "Local IP addresses:"
    if command -v ip >/dev/null; then
        # Linux with ip command
        ip -4 addr show | awk '/inet / {split($2, a, "/"); if (a[1] != "127.0.0.1") print a[1]}'
    elif command -v ifconfig >/dev/null; then
        # macOS and older systems
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    fi

    echo ""
    echo "Public IP address:"
    if command -v curl >/dev/null; then
        curl -s https://api.ipify.org
        echo ""
    elif command -v wget >/dev/null; then
        wget -qO- https://api.ipify.org
        echo ""
    fi
}
