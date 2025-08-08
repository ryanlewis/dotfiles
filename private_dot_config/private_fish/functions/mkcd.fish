function mkcd --description "Create a directory and cd into it"
    if test (count $argv) -eq 0
        echo "Usage: mkcd <directory>"
        return 1
    end
    mkdir -p $argv[1] && cd $argv[1]
end