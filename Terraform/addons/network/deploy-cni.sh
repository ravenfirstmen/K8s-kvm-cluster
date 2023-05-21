#!/bin/bash

kubectl apply -k ./cni/calico/

kubectl wait --namespace kube-system --for=condition=Ready pods --all --timeout=90s