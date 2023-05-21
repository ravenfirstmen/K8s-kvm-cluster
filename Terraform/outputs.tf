output "cluster-nodes" {
  value = [for s in local.all_machines : s.name]
}


output "control-pane" {
  value = {
    name    = local.controller_node.name
    address = local.controller_node.ip
    fqdn    = local.controller_node.fqdn
  }
}
output "load-balancer" {
  value = {
    name    = local.load_balancer_server.name
    address = local.load_balancer_server.ip
    fqdn    = local.load_balancer_server.fqdn
  }
}
output "workers" {
  value = {
    for s in local.worker_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}

output "cluster_name" {
  value = var.cluster_name
}

output "etc_hosts" {
  value = data.template_file.etc_hosts.rendered
}


# scripts
resource "local_file" "create_routes_script" {
  content = <<EOF
  #!/bin/bash

  # Execute this to have routing between the two networks

  sudo iptables -I FORWARD -j ACCEPT -i ${libvirt_network.zone1_cluster_network.bridge} -o ${libvirt_network.zone2_cluster_network.bridge} -s "${var.network_zone1_cidr}" -d "${var.network_zone2_cidr}"
  sudo iptables -I FORWARD -j ACCEPT -i ${libvirt_network.zone2_cluster_network.bridge} -o ${libvirt_network.zone1_cluster_network.bridge} -s "${var.network_zone2_cidr}" -d "${var.network_zone1_cidr}"

  EOF

  filename        = "./zones-routing-create.sh"
  file_permission = "0700"
}

resource "local_file" "delete_routes_script" {
  content = <<EOF
  #!/bin/bash

  # Execute this to remove the previous routing between the two networks

  sudo iptables -D FORWARD -j ACCEPT -i ${libvirt_network.zone1_cluster_network.bridge} -o ${libvirt_network.zone2_cluster_network.bridge} -s "${var.network_zone1_cidr}" -d "${var.network_zone2_cidr}"
  sudo iptables -D FORWARD -j ACCEPT -i ${libvirt_network.zone2_cluster_network.bridge} -o ${libvirt_network.zone1_cluster_network.bridge} -s "${var.network_zone2_cidr}" -d "${var.network_zone1_cidr}"

  EOF

  filename        = "./zones-routing-delete.sh"
  file_permission = "0700"
}

