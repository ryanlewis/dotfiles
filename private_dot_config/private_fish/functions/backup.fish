function backup --description "Create a backup of a file with timestamp"
    if test (count $argv) -eq 0
        echo "Usage: backup <file>"
        return 1
    end
    
    set -l file $argv[1]
    if not test -e $file
        echo "Error: $file does not exist"
        return 1
    end
    
    set -l timestamp (date +%Y%m%d_%H%M%S)
    set -l backup_name "$file.backup_$timestamp"
    
    cp -a $file $backup_name
    echo "Backup created: $backup_name"
end