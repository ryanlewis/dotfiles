# Fuzzy kill process
fkill() {
    local pid
    pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
    if [[ -n $pid ]]; then
        echo "$pid" | xargs kill -9
        echo "Killed process(es): $pid"
    fi
}
