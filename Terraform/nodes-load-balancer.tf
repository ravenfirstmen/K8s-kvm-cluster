
resource "libvirt_cloudinit_disk" "load_balancer_cloudinit" {
  name           = local.load_balancer_server.cloudinit
  pool           = libvirt_pool.cluster.name
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.machine_id[local.load_balancer_server.name].result, hostname = local.load_balancer_server.name })
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})

  user_data = data.template_cloudinit_config.load_balancer_cloud_init.rendered
}

data "template_cloudinit_config" "load_balancer_cloud_init" {
  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

hostname: ${local.load_balancer_server.name}
preserve_hostname: false
fqdn: ${local.load_balancer_server.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text

ssh_authorized_keys:
  - "${local.load_balancer_server.ssh_key}"

ca_certs:
  trusted:
    - |
      ${indent(6, data.tls_certificate.k8s_ca_cert.certificates[0].cert_pem)}

write_files:
  - encoding: b64
    content: ${base64encode(tls_private_key.ssh.private_key_pem)}
    path: /home/ubuntu/.ssh/id_rsa
    owner: ubuntu:ubuntu
    permissions: 0600
    defer: true

  - encoding: b64
    content: ${base64encode(data.template_file.etc_hosts.rendered)}
    path: /etc/hosts
    append: true

  - encoding: b64
    content: ${base64encode(data.template_file.ha_proxy_nodes.rendered)}
    path: /etc/haproxy/haproxy.cfg
    permissions: 0644
    append: true

runcmd:
 - [ systemctl, enable, haproxy ]
 - [ systemctl, start, haproxy ]
 - [ systemctl, stop, kubelet ]
 - [ systemctl, disable, kubelet ]
EOT
  }

}

# aolso expose well-know ports from the ingress controller service
data "template_file" "ha_proxy_nodes" {
  template = <<-EOT

frontend http_front
    mode tcp
    bind *:80
    option tcplog
    default_backend http_back

frontend https_front
    mode tcp
    bind *:443
    option tcplog
    default_backend https_back

backend http_back
    mode tcp
    balance roundrobin
%{~for s in local.worker_nodes}
${format("    server %s %s:32700 check", s.name, s.ip)}
%{~endfor}

backend https_back
    mode tcp
    balance roundrobin
    option ssl-hello-chk
%{~for s in local.worker_nodes}
${format("    server %s %s:32701 check", s.name, s.ip)}
%{~endfor}

listen stats
    stats enable
    bind *:1936
    mode http
    stats uri /
    stats hide-version
    stats auth admin:admin
  EOT
}

resource "libvirt_domain" "loadbalancer-machine" {
  name   = local.load_balancer_server.name
  vcpu   = var.virtual_cpus_loadbalancer
  memory = var.virtual_memory_loadbalancer

  autostart = false
  machine   = "q35"

  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  #qemu_agent = true

  firmware  = "${local.uefi_location_files}/OVMF_CODE_4M.fd"
  cloudinit = libvirt_cloudinit_disk.load_balancer_cloudinit.id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.load-balancer-node-vm-disk.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  network_interface {
    network_id     = local.load_balancer_server.network_id
    hostname       = local.load_balancer_server.name
    addresses      = [local.load_balancer_server.ip]
    wait_for_lease = true
  }

  depends_on = [
    libvirt_cloudinit_disk.load_balancer_cloudinit,
    libvirt_network.zone1_cluster_network
  ]
}

resource "libvirt_volume" "load-balancer-node-vm-disk" {
  name             = local.load_balancer_server.volume
  pool             = libvirt_pool.cluster.name
  base_volume_pool = var.base_volume_pool
  base_volume_name = var.base_volume_name
}
