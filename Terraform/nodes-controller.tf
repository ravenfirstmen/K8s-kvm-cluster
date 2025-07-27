
resource "libvirt_cloudinit_disk" "controller_cloudinit" {
  name           = local.controller_node.cloudinit
  pool           = libvirt_pool.cluster.name
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.machine_id[local.controller_node.key].result, hostname = local.controller_node.name })
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})

  user_data = data.template_cloudinit_config.config[local.controller_node.key].rendered
}


resource "libvirt_domain" "controller-machine" {
  name   = local.controller_node.name
  vcpu   = var.virtual_cpus_controller
  memory = var.virtual_memory_controller

  autostart = false
  machine   = "q35"

  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  #qemu_agent = true

  firmware  = "${local.uefi_location_files}/OVMF_CODE_4M.fd"
  cloudinit = libvirt_cloudinit_disk.controller_cloudinit.id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.controller-node-vm-disk.id
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
    network_id     = local.controller_node.network_id
    hostname       = local.controller_node.name
    addresses      = [local.controller_node.ip]
    wait_for_lease = true
  }

  depends_on = [
    libvirt_cloudinit_disk.controller_cloudinit,
    libvirt_network.zone1_cluster_network
  ]
}

resource "libvirt_volume" "controller-node-vm-disk" {
  name             = local.controller_node.volume
  pool             = libvirt_pool.cluster.name
  base_volume_pool = var.base_volume_pool
  base_volume_name = var.base_volume_name
}
