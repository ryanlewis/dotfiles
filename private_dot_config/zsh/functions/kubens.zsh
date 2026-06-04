# Switch K8s namespaces (with fzf)
kubens() {
    if (( $# == 0 )); then
        local ns
        ns=$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | fzf) \
            && kubectl config set-context --current --namespace="$ns"
    else
        command kubens "$@"
    fi
}
