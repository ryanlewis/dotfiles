# Extract various archive formats
extract() {
    if (( $# == 0 )); then
        echo "Usage: extract <archive>"
        return 1
    fi
    local file=$1
    if [[ ! -f $file ]]; then
        echo "Error: '$file' is not a valid file"
        return 1
    fi
    case $file in
        *.tar.bz2) tar xjf "$file" ;;
        *.tar.gz)  tar xzf "$file" ;;
        *.tar.xz)  tar xJf "$file" ;;
        *.bz2)     bunzip2 "$file" ;;
        *.rar)     unrar x "$file" ;;
        *.gz)      gunzip "$file" ;;
        *.tar)     tar xf "$file" ;;
        *.tbz2)    tar xjf "$file" ;;
        *.tgz)     tar xzf "$file" ;;
        *.zip)     unzip "$file" ;;
        *.Z)       uncompress "$file" ;;
        *.7z)      7z x "$file" ;;
        *)         echo "Error: '$file' cannot be extracted via extract()"; return 1 ;;
    esac
}
