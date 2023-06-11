#!/bin/bash

kubectl apply -k ./k8s-dashboard/

kubectl wait --namespace kubernetes-dashboard --for=condition=Ready pod --all --timeout=90s
