# Create a backup of a file with timestamp
backup() {
    if (( $# == 0 )); then
        echo "Usage: backup <file>"
        return 1
    fi
    local file=$1
    if [[ ! -e $file ]]; then
        echo "Error: $file does not exist"
        return 1
    fi
    local timestamp backup_name
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_name="${file}.backup_${timestamp}"
    cp -a "$file" "$backup_name"
    echo "Backup created: $backup_name"
}
