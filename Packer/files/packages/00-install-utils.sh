#!/bin/bash

set -e -v

sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install jq -y && sudo apt-get install wget -y

# yq = jq for yaml
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq 
