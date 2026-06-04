# Switch K8s contexts (with fzf)
kubectx() {
    if (( $# == 0 )); then
        local ctx
        ctx=$(kubectl config get-contexts -o name | fzf) && kubectl config use-context "$ctx"
    else
        command kubectx "$@"
    fi
}
