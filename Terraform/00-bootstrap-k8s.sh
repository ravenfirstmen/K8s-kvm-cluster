#!/bin/bash

TMP_DIR=./tmp
KUBERNETES_VERSION=1.32.7

if [ -d "$TMP_DIR" ];
then
    rm -rf $TMP_DIR
fi

mkdir -p $TMP_DIR

terraform apply -auto-approve

sleep 15

# Execute to init the k8s cp
CONTROLLER=$(terraform output -json control-pane | jq -r '.address')
CONTROLLER_FQDN=$(terraform output -json control-pane | jq -r '.fqdn')
CLUSTER_NAME=$(terraform output -raw cluster_name)
WORKERS=($(terraform output -json workers | jq -r '.[].address'))
LOAD_BALANCER=($(terraform output -json load-balancer | jq -r '.address'))
JOIN_CMD_FILE_NAME="join-node.sh"
JOIN_CMD="$TMP_DIR/$JOIN_CMD_FILE_NAME"
CONFIG_FILE=".kube/config"
LOCAL_CONFIG_FILE="$TMP_DIR/kubectl-config"

ssh -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$CONTROLLER <<EOT
  sudo kubeadm init --kubernetes-version v${KUBERNETES_VERSION} --control-plane-endpoint $CONTROLLER_FQDN --pod-network-cidr "10.0.0.0/16" --service-cidr "10.2.0.0/16"
  mkdir -p \$HOME/.kube
  sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config
  sudo chown $(id -u):$(id -g) \$HOME/.kube/config
  kubeadm token create --print-join-command > $JOIN_CMD_FILE_NAME
EOT

if [ ! -f "$JOIN_CMD" ];
then
  scp -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$CONTROLLER:$JOIN_CMD_FILE_NAME $JOIN_CMD
fi

for worker in ${WORKERS[@]};
do
    echo "Join worker $worker ..."
ssh -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$worker <<EOT
    sudo $(cat $JOIN_CMD)
EOT
done

echo "Join load balancer $LOAD_BALANCER ..."
ssh -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$LOAD_BALANCER <<EOT
    sudo $(cat $JOIN_CMD)
EOT

if [ ! -f "$LOCAL_CONFIG_FILE" ];
then
  scp -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$CONTROLLER:$CONFIG_FILE $LOCAL_CONFIG_FILE
fi

mkdir -p $HOME/.kube

export KUBECONFIG=$LOCAL_CONFIG_FILE:~/.kube/config
kubectl config view --flatten > $TMP_DIR/config
cp -f $TMP_DIR/config ~/.kube/config

rm -rf $TMP_DIR

# Labels
CONTROLLER_FQDN=$(terraform output -json control-pane | jq -r '.fqdn')
kubectl label node ${CONTROLLER_FQDN} node-role.kubernetes.io/control-plane=true --overwrite
kubectl label node ${CONTROLLER_FQDN} node-role=control-plane

WORKERS=($(terraform output -json workers | jq -r '.[].fqdn'))
for worker in ${WORKERS[@]};
do
  kubectl label node ${worker} node-role=worker --overwrite
done

LOAD_BALANCER=($(terraform output -json load-balancer | jq -r '.fqdn'))
kubectl label node ${LOAD_BALANCER} node-role=load-balancer --overwrite
