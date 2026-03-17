function kubens --description "Switch K8s namespaces (with fzf)"
    if test (count $argv) -eq 0
        kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | fzf | read -l ns
        and kubectl config set-context --current --namespace=$ns
    else
        command kubens $argv
    end
end
