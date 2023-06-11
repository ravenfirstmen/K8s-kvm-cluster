#!/bin/bash

# cni
kubectl apply -k ./bootstrap/network/calico/
kubectl wait --namespace kube-system --for=condition=Ready pods --all --timeout=90s

# storage
kubectl apply -k ./bootstrap/storage/
kubectl wait --namespace local-path-storage --for=condition=Ready pods --all --timeout=90s

# ingress
kubectl apply -k ./bootstrap/ingress/nginx/
kubectl wait --namespace ingress-nginx --for=condition=complete job --selector=app.kubernetes.io/component=admission-webhook --timeout=90s
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

#cert-manager & load the CA
kubectl apply -k bootstrap/certificates/
kubectl wait --namespace cert-manager --for=condition=Ready pods --all --timeout=90s

kubectl apply -f - <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: ca-key-pair
  namespace: cert-manager
data:
  tls.crt: $(base64 -w 0 ./certs/public-ca-crt.pem)
  tls.key: $(base64 -w 0 ./certs/public-ca-key.pem)

---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: ca-key-pair
EOT
