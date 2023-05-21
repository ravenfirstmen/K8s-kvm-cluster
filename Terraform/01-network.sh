#!/bin/bash

# cni
kubectl apply -k ./addons/network/cni/calico/
kubectl wait --namespace kube-system --for=condition=Ready pods --all --timeout=90s

# ingress
kubectl apply -k ./addons/network/ingress/nginx/
kubectl wait --namespace ingress-nginx --for=condition=complete job --selector=app.kubernetes.io/component=admission-webhook --timeout=90s
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
