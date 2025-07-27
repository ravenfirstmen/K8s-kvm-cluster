#!/bin/bash

set -e -v # exit on first error

sudo apt-get autoremove -y && sudo apt-get clean -y && sudo apt-get autoclean -y

#exclude directories with sticky bit.
sudo find /var/log/* -type d ! -perm /1000 | while read d; do sudo find $d -type f | while read f; do echo '' | sudo tee $f 1>/dev/null; done; done

[ -f /home/ubuntu/.bash_history ] && rm /home/ubuntu/.bash_history

sudo cloud-init clean --logs --machine-id

echo 'uninitialized' | sudo tee /etc/machine-id
sudo chmod a-wx,a+r /etc/machine-id

sudo tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg <<EOF
datasource_list: [ NoCloud ]
EOF

sudo tee /etc/cloud/cloud.cfg.d/10_datasource.cfg <<EOF
datasource:
  NoCloud:
    fs_label: cidata
EOF
