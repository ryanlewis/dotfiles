# Show listening ports
ports() {
    if command -v lsof >/dev/null; then
        # macOS and systems with lsof
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    elif command -v ss >/dev/null; then
        # Modern Linux with ss
        sudo ss -tulpn | grep LISTEN
    elif command -v netstat >/dev/null; then
        # Fallback to netstat
        sudo netstat -tulpn | grep LISTEN
    else
        echo "No suitable command found to list ports"
        return 1
    fi
}
