# Create a directory and cd into it
mkcd() {
    if (( $# == 0 )); then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}
