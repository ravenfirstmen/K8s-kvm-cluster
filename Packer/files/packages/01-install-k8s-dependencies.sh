#!/bin/bash

set -e -v

REPO_VERSION=$INSTALLABLE_K8S_VERSION-00

sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl

# kubernetes
#sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# helm 
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

sudo apt-get update -y

sudo apt-get install -y containerd.io kubectl=$REPO_VERSION kubelet=$REPO_VERSION kubeadm=$REPO_VERSION 
sudo apt-mark hold containerd.io kubectl=$REPO_VERSION kubelet=$REPO_VERSION kubeadm=$REPO_VERSION 
sudo apt-get install helm -y

