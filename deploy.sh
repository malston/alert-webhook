#!/usr/bin/env bash

kubectl delete configmap am-webhook-config --ignore-not-found
kubectl create configmap am-webhook-config --from-file=config/ --namespace=monitoring

kubectl delete deploy alert-webhook --ignore-not-found
kubectl create -f deployment.yaml
