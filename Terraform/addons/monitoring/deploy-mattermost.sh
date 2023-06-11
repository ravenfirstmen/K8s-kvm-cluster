#!/bin/bash

kubectl create ns mattermost-operator
kubectl apply -n mattermost-operator -f ./mattermost/mattermost-operator.yaml

# kubectl create ns mysql-operator
# kubectl apply -n mysql-operator -f ./mattermost/mysql-operator.yaml

kubectl create ns minio-operator
kubectl apply -n minio-operator -f ./mattermost/minio-operator.yaml

# https://docs.mattermost.com/install/prepare-mattermost-database.html
# to prepare the db
# kubectl exec -it postgres-0 -n postgres -- sh
# CREATE DATABASE mattermost;
# CREATE USER mmuser WITH PASSWORD 'mmuser';
# GRANT ALL PRIVILEGES ON DATABASE mattermost to mmuser;
# https://www.cybertec-postgresql.com/en/error-permission-denied-schema-public/
# GRANT ALL ON SCHEMA public TO mmuser;
# Don't use these secrets in PRD!!!!!

kubectl create ns mattermost

cat <<EOT > ./mattermost/tls.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mattermost-tls
  namespace: mattermost
type: Opaque
data:
  tls.crt: $(base64 -w 0 ../../certs/mattermost-crt.pem)
  tls.key: $(base64 -w 0 ../../certs/mattermost-key.pem)
EOT

kubectl apply -n mattermost -f ./mattermost/tls.yaml
kubectl apply -n mattermost -f ./mattermost/postgres-secrets.yaml
kubectl apply -n mattermost -f ./mattermost/mattermost-installation.yaml

#kubectl -n mattermost port-forward svc/mm-demo 8065:8065
