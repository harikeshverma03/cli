if [[ $1 = "set-ns" ]]
then
  kubectl config set-context --current --namespace=$2
elif [[ $1 = "get-all" ]]
then
    if [ -z "$2" ]; then
        kubectl get all | column -t | awk '
        NR==1 {print; next}
        /pod/ {print "\033[32m" $0 "\033[39m"; next}
        /service/ {print "\033[34m" $0 "\033[39m"; next}
        /deployment/ {print "\033[35m" $0 "\033[39m"; next}
        /replicaset/ {print "\033[36m" $0 "\033[39m"; next}
        {print}'
    else
        kubectl get all | grep $2 | column -t | awk '
        NR==1 {print; next}
        /pod/ {print "\033[32m" $0 "\033[39m"; next}
        /service/ {print "\033[34m" $0 "\033[39m"; next}
        /deployment/ {print "\033[35m" $0 "\033[39m"; next}
        /replicaset/ {print "\033[36m" $0 "\033[39m"; next}
        {print}'
    fi
elif [[ $1 = "pods" || $1 = "deploy" || $1 = "httproutes" ]]
then
    if [ -z "$2" ]; then
        kubectl get $1 | column -t | awk '
        NR==1 {print; next}
        /pod/ {print "\033[32m" $0 "\033[39m"; next}
        /service/ {print "\033[34m" $0 "\033[39m"; next}
        /deployment/ {print "\033[35m" $0 "\033[39m"; next}
        /replicaset/ {print "\033[36m" $0 "\033[39m"; next}
        {print}'
    else
        kubectl get $1 | grep $2 | column -t | awk '
        NR==1 {print; next}
        /pod/ {print "\033[32m" $0 "\033[39m"; next}
        /service/ {print "\033[34m" $0 "\033[39m"; next}
        /deployment/ {print "\033[35m" $0 "\033[39m"; next}
        /replicaset/ {print "\033[36m" $0 "\033[39m"; next}
        {print}'
    fi
elif [[ $1 = "describe" ]]
then
    if [ -z "$2" ]; then
        echo "Please provide the resource type (e.g., pods, deploy)"
        exit 1
    fi

    if [ -z "$3" ]; then
        RESOURCE_LIST=$(kubectl get $2 -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get $2 -o wide | grep $3 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Describing $2: $RESOURCE_NAME"
    kubectl describe $2 $RESOURCE_NAME
elif [[ $1 = "ssh" ]]
then
    if [ -z "$2" ]; then
        RESOURCE_LIST=$(kubectl get pods -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get pods -o wide | grep $2 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Running sh command in pod: $RESOURCE_NAME"
    kubectl exec -it $RESOURCE_NAME -- sh
elif [[ $1 = "bash" ]]
then
    if [ -z "$2" ]; then
        RESOURCE_LIST=$(kubectl get pods -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get pods -o wide | grep $2 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Running bash command in pod: $RESOURCE_NAME"
    kubectl exec -it $RESOURCE_NAME -- bash
elif [[ $1 = "logs" ]]
then
    if [ -z "$2" ]; then
        RESOURCE_LIST=$(kubectl get pods -o wide | column -t | fzf --reverse --height 10)
    else
        RESOURCE_LIST=$(kubectl get pods -o wide | grep $2 | column -t | fzf --reverse --height 10)
    fi
    [ -z "$RESOURCE_LIST" ] && exit 1
    RESOURCE_NAME=$(echo $RESOURCE_LIST | awk '{print $1}')
    echo "Fetching logs for pod: $RESOURCE_NAME"
    kubectl logs -f $RESOURCE_NAME
fi