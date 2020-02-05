#!/usr/bin/env bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

namespace="monitoring"

kubectl delete configmap -n "${namespace}" am-webhook-config --ignore-not-found
kubectl create configmap -n "${namespace}" am-webhook-config --from-file=config/

kubectl delete deploy alert-webhook -n "${namespace}" --ignore-not-found
kubectl apply -f deployment.yaml -n "${namespace}"