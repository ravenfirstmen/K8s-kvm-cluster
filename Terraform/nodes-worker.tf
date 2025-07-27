resource "libvirt_cloudinit_disk" "worker_cloudinit" {
  for_each = local.worker_nodes

  name           = each.value.cloudinit
  pool           = libvirt_pool.cluster.name
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.machine_id[each.key].result, hostname = each.value.name })
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})

  user_data = data.template_cloudinit_config.config_worker_nodes[each.key].rendered
}

# device_aliases:
#   data_disk: /dev/vdb
# disk_setup:
#   data_disk:
#     table_type: gpt
#     layout: true
#     overwrite: true
# fs_setup:
# - label: data
#   device: data_disk.1
#   filesystem: ext4
# mounts:
# - ["data_disk.1", "/data"]


resource "libvirt_domain" "worker-machine" {
  for_each = local.worker_nodes

  name   = each.value.name
  vcpu   = var.virtual_cpus_worker_nodes
  memory = var.virtual_memory_worker_nodes

  autostart = false
  machine   = "q35"

  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  #qemu_agent = true

  firmware  = "${local.uefi_location_files}/OVMF_CODE_4M.fd"
  cloudinit = libvirt_cloudinit_disk.worker_cloudinit[each.key].id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.worker-node-vm-disk[each.key].id
  }


  disk {
    volume_id = libvirt_volume.worker-node-vm-data-disk[each.key].id
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
    network_id     = each.value.network_id
    hostname       = each.value.name
    addresses      = [each.value.ip]
    wait_for_lease = true
  }

  depends_on = [
    libvirt_cloudinit_disk.worker_cloudinit
  ]
}

resource "libvirt_volume" "worker-node-vm-disk" {
  for_each = local.worker_nodes

  #   workaround: depend on libvirt_ignition.ignition[each.key], otherwise the VM will use the old disk when the user-data changes
  #   name           = "${each.value.name}-${md5(libvirt_ignition.worker_node_ignition[each.key].id)}.qcow2"
  name             = each.value.volume
  pool             = libvirt_pool.cluster.name
  base_volume_pool = var.base_volume_pool
  base_volume_name = var.base_volume_name
}

resource "libvirt_volume" "worker-node-vm-data-disk" {
  for_each = local.worker_nodes

  name = "${each.value.volume}-data"
  pool = libvirt_pool.cluster.name
  size = 20 * 1024 * 1024 * 1024
}
