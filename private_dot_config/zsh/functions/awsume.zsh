# Redirect awsume users to granted's assume
awsume() {
    echo "Use 'assume' instead (granted)" >&2
    return 1
}
