
source "libvirt" "k8s" {
  libvirt_uri = "qemu:///system"
  #libvirt_uri = "qemu+tcp://my-remote-example/system"
  # qemu+tls://127.0.0.1/system?pkipath=/home/pzak/libvirt-cert

  vcpu     = 2
  memory   = 4096
  cpu_mode = "host-passthrough"

  chipset     = "q35"
  loader_type = "rom"
  loader_path = "/usr/share/OVMF/OVMF_CODE.fd"

  network_interface {
    type  = "managed"
    alias = "communicator"
  }

  communicator {
    communicator         = "ssh"
    ssh_username         = "ubuntu"
    ssh_private_key_file = "./key-packer"
  }

  network_address_source = "lease"

  volume {
    alias  = "artifact"
    format = "qcow2"

    pool = var.volume_pool
    name = var.final_image_name

    source {
      type = "external"
      urls = ["file://${var.source_img_file}"]
    }

    size     = "100G"
    capacity = "100G"

    bus        = "virtio"
    target_dev = "vda"
  }

  volume {
    source {
      type = "cloud-init"

      network_config = jsonencode({
        version = 2
        ethernets = {
          eth = {
            match = {
              name = "en*"
            }
            dhcp4 = true
          }
        }
      })

      user_data = <<EOT
#cloud-config
resize_rootfs: true

chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text 

ssh_pwauth: False
ssh_authorized_keys:
  - "${file("key-packer.pub")}"

packages_update: true
packages_upgrade: true
packages:
  - apt-utils
  - qemu-guest-agent

runcmd:
  - [ "systemctl", "enable", "--now", "qemu-guest-agent" ]

timezone: Europe/Lisbon
    EOT

    }
    capacity = "1M"

    bus        = "sata"
    target_dev = "sda"
  }

}

