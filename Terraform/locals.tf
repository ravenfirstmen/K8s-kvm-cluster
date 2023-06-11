locals {
  uefi_location_files = "/usr/share/OVMF"
  nvram_location      = "/var/lib/libvirt/qemu/nvram"
}

# https://github.com/dmacvicar/terraform-provider-libvirt/issues/778

locals {
  z1_n_nodes = var.zone1_n_nodes + 1
  #cluster_domain_fqdn = "${var.cluster_name}.${var.network_domain}"
  cluster_domain_fqdn = var.network_domain

  load_balancer_server = {
    name          = "lb"
    is_k8s_node   = false
    is_controller = false
    fqdn          = "lb.${local.cluster_domain_fqdn}"
    ip            = "${cidrhost(var.network_zone1_cidr, 2)}"
    ip_cidr       = "${cidrhost(var.network_zone1_cidr, 2)}/24"
    network_id    = libvirt_network.zone1_cluster_network.id
    gateway       = local.zone1_network_gateway
    volume        = "${var.cluster_name}-lb" # de momento ignorado
    cloudinit     = "${var.cluster_name}-lb-cloudinit.iso"
    ssh_key       = tls_private_key.ssh.public_key_openssh
    index         = 0
    key           = "${var.cluster_name}-lb-zone1"
  }

  zone1_k8s_cluster_nodes = { # +1 is for the controller
    for n in range(local.z1_n_nodes) : "${var.cluster_name}-node${n}-zone1" => {
      name          = n == 0 ? "cp" : "worker${n}"
      is_k8s_node   = true
      is_controller = n == 0 ? true : false
      fqdn          = n == 0 ? "cp.${local.cluster_domain_fqdn}" : "worker${n}.${local.cluster_domain_fqdn}"
      ip            = "${cidrhost(var.network_zone1_cidr, n + 10)}"
      ip_cidr       = "${cidrhost(var.network_zone1_cidr, n + 10)}/24"
      network_id    = libvirt_network.zone1_cluster_network.id
      gateway       = local.zone1_network_gateway
      volume        = "${var.cluster_name}-worker${n}" # de momento ignorado
      cloudinit     = "${var.cluster_name}-worker${n}-cloudinit.iso"
      ssh_key       = tls_private_key.ssh.public_key_openssh
      index         = n
      key           = "${var.cluster_name}-node${n}-zone1"
    }
  }

  zone2_k8s_cluster_nodes = {
    for n in range(var.zone2_n_nodes) : "${var.cluster_name}-node${n}-zone2" => {
      name          = "worker${n + local.z1_n_nodes}"
      is_k8s_node   = true
      is_controller = false
      fqdn          = "worker${n + local.z1_n_nodes}.${local.cluster_domain_fqdn}"
      ip            = "${cidrhost(var.network_zone2_cidr, n + 10)}"
      ip_cidr       = "${cidrhost(var.network_zone2_cidr, n + 10)}/24"
      network_id    = libvirt_network.zone2_cluster_network.id
      gateway       = local.zone2_network_gateway
      volume        = "${var.cluster_name}-worker${n + local.z1_n_nodes}" # de momento ignorado
      cloudinit     = "${var.cluster_name}-worker${n + local.z1_n_nodes}-cloudinit.iso"
      ssh_key       = tls_private_key.ssh.public_key_openssh
      index         = n + local.z1_n_nodes
      key           = "${var.cluster_name}-node${n}-zone1"
    }
  }

}

locals {
  non_k8s_nodes   = { for s in [local.load_balancer_server] : s.name => s }
  k8s_nodes       = merge(local.zone1_k8s_cluster_nodes, local.zone2_k8s_cluster_nodes)
  all_machines    = merge(local.non_k8s_nodes, local.k8s_nodes)
  controler_nodes = [for key, node in local.k8s_nodes : node if node.is_controller]
  worker_nodes    = { for key, node in local.k8s_nodes : key => node if !node.is_controller }
  controller_node = element(local.controler_nodes, 0)
}
