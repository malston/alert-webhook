#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

function create_token() {
    echo -n "creating token"
    echo ""
    make build-token

    ./alert-webhook-token

    kubectl delete configmap -n "${namespace}" am-webhook-config --ignore-not-found
    kubectl create configmap -n "${namespace}" am-webhook-config --from-file=config/
}

namespace="${1:-amhook}"
create_token="${2}"

if [[ $create_token ]]; then
    create_token
fi

kubectl delete deploy alert-webhook -n "${namespace}" --ignore-not-found
kubectl create -f deployment.yaml -n "${namespace}"