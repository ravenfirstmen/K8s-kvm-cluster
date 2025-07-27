#!/bin/bash

TF_PROVISIONED_DOMAINS=$(terraform -chdir=.. output -json cluster-nodes | jq -r '.[]')

for domain in ${TF_PROVISIONED_DOMAINS} ; do
    if ! [[ $(virsh --connect qemu:///system list | grep $domain | grep 'running$') ]] ; then
        virsh --connect qemu:///system start "$domain"
    fi

done
