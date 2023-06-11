#cloud-config

hostname: ${host_name}
preserve_hostname: false
fqdn: ${host_fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text

ssh_authorized_keys:
  - "${ssh_key}"

ca_certs:
  trusted:
    - |
      ${indent(6, ca_cert_pem)}

write_files:
  - encoding: b64
    content: ${base64encode(ssh_private_key_pem)}
    path: /home/ubuntu/.ssh/id_rsa
    owner: ubuntu:ubuntu
    permissions: 0600
    defer: true

  - encoding: b64
    content: ${base64encode(etc_hosts)}
    path: /etc/hosts
    append: true
