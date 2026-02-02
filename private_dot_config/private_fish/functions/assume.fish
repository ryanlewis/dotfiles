# Granted assume function - AWS credential management
# Sources the assume.fish script from mise-installed granted
function assume --description "Assume AWS role via granted"
    set -l granted_path (mise where aqua:common-fate/granted 2>/dev/null)
    if test -z "$granted_path"
        echo "Error: granted not installed via mise. Run: mise install" >&2
        return 1
    end

    set -l assume_script "$granted_path/assume.fish"
    if test -f "$assume_script"
        source "$assume_script" $argv
    else
        echo "Error: assume.fish not found at $assume_script" >&2
        return 1
    end
end
