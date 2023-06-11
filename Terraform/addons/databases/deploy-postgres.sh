#!/bin/bash

kubectl apply -k ./postgres/

kubectl wait --namespace postgres --for=condition=Ready pods --all --timeout=90s
