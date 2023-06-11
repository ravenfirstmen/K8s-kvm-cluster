resource "random_uuid" "machine_id" {
  for_each = local.all_machines
}

locals {
  mandatory_cloudinit_config_part = <<EOT
#cloud-config

hostname: $${each.value.name}
preserve_hostname: false
fqdn: $${each.value.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text

ssh_authorized_keys:
  - "$${each.value.ssh_key}"

ca_certs:
  trusted:
    - |
      $${indent(6, data.tls_certificate.k8s_ca_cert.certificates[0].cert_pem)}

write_files:
  - encoding: b64
    content: $${base64encode(tls_private_key.ssh.private_key_pem)}
    path: /home/ubuntu/.ssh/id_rsa
    owner: ubuntu:ubuntu
    permissions: 0600
    defer: true

  - encoding: b64
    content: $${base64encode(data.template_file.etc_hosts.rendered)}
    path: /etc/hosts
    append: true
EOT

}

data "template_cloudinit_config" "config" {
  for_each = local.all_machines

  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/base_cloud_init.tpl", {
      host_name           = each.value.name,
      host_fqdn           = each.value.fqdn,
      ssh_key             = each.value.ssh_key,
      ca_cert_pem         = data.tls_certificate.k8s_ca_cert.certificates[0].cert_pem,
      ssh_private_key_pem = tls_private_key.ssh.private_key_pem,
      etc_hosts           = data.template_file.etc_hosts.rendered
    })
  }
}

data "template_cloudinit_config" "config_worker_nodes" {
  for_each = local.worker_nodes

  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/base_cloud_init.tpl", {
      host_name           = each.value.name,
      host_fqdn           = each.value.fqdn,
      ssh_key             = each.value.ssh_key,
      ca_cert_pem         = data.tls_certificate.k8s_ca_cert.certificates[0].cert_pem,
      ssh_private_key_pem = tls_private_key.ssh.private_key_pem,
      etc_hosts           = data.template_file.etc_hosts.rendered
    })
  }

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
device_aliases:
  data_disk: /dev/vdb
disk_setup:
  data_disk:
    table_type: gpt
    layout: true
    overwrite: true
fs_setup:
- label: data
  device: data_disk.1
  filesystem: ext4
mounts:
- ["data_disk.1", "/data"]
EOT
  }
}
