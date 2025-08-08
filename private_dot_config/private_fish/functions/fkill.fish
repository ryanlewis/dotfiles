function fkill --description "Fuzzy kill process"
    set -l pid (ps aux | sed 1d | fzf -m | awk '{print $2}')
    if test -n "$pid"
        echo $pid | xargs kill -9
        echo "Killed process(es): $pid"
    end
end