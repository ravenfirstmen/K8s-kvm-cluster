#!/bin/bash

# Daqui https://github.com/kubernetes/dashboard/blob/master/docs/user/installation.md#recommended-setup
# Desafio: instalar cert-manager e perceber como funciona e se pode integrar :)

cat <<EOT > ./addons/monitoring/k8s-dashboard/custom-certs-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: kubernetes-dashboard-certs
  namespace: kubernetes-dashboard
type: Opaque
data:
  tls.crt: $(base64 -w 0 ./certs/dashboard-crt.pem)
  tls.key: $(base64 -w 0 ./certs/dashboard-key.pem)
EOT

kubectl apply -k ./addons/monitoring/k8s-dashboard/

kubectl wait --namespace kubernetes-dashboard --for=condition=Ready pod --all --timeout=90s