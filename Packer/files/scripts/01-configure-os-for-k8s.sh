#!/bin/bash

set -e -v

# Ensure swap is disabled. It should by default in cloud image but just in case
sudo swapoff -a

# Ensure the overlay and bridge drivers are enabled
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# They exist?
sudo modprobe overlay
sudo modprobe br_netfilter

# Ensure forward is enable
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# All ok?
sudo sysctl --system

# override containerd settings
sudo containerd config default | sudo tee /etc/containerd/config.toml
# Enable CGroups
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Everything ok?
sudo systemctl restart containerd

# Ensure kubelet and containerd  are enable at boot
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service
sudo systemctl start containerd.service

# pre pull images
sudo kubeadm config images pull --kubernetes-version v$INSTALLABLE_K8S_VERSION
