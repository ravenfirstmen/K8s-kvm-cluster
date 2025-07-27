#!/bin/bash

TMP_DIR=./tmp

if [ -d "$TMP_DIR" ];
then
    rm -rf $TMP_DIR
fi

mkdir -p $TMP_DIR

terraform apply -auto-approve

# Execute to init the k8s cp
CONTROLLER=$(terraform output -json control-pane | jq -r '.address')
CONTROLLER_FQDN=$(terraform output -json control-pane | jq -r '.fqdn')
CLUSTER_NAME=$(terraform output -raw cluster_name)
WORKERS=($(terraform output -json workers | jq -r '.[].address'))
JOIN_CMD_FILE_NAME="join-node.sh"
JOIN_CMD="$TMP_DIR/$JOIN_CMD_FILE_NAME"
CONFIG_FILE=".kube/config"
LOCAL_CONFIG_FILE="$TMP_DIR/kubectl-config"

ssh -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$CONTROLLER <<EOT
  sudo kubeadm init --kubernetes-version v1.26.4 --control-plane-endpoint $CONTROLLER_FQDN --pod-network-cidr "10.0.0.0/16" --service-cidr "10.2.0.0/16"
  mkdir -p \$HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
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

if [ ! -f "$LOCAL_CONFIG_FILE" ];
then
  scp -i ssh-$CLUSTER_NAME-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$CONTROLLER:$CONFIG_FILE $LOCAL_CONFIG_FILE
fi

mkdir -p $HOME/.kube
cp $LOCAL_CONFIG_FILE $HOME/.kube/config

rm -rf $TMP_DIR
