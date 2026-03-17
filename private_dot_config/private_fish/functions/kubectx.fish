function kubectx --description "Switch K8s contexts (with fzf)"
    if test (count $argv) -eq 0
        kubectl config get-contexts -o name | fzf | read -l ctx
        and kubectl config use-context $ctx
    else
        command kubectx $argv
    end
end
