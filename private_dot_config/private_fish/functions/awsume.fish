# Redirect awsume users to granted's assume
function awsume --description "Redirects to assume (granted)"
    echo "Use 'assume' instead (granted)" >&2
    return 1
end
