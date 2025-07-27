source "qemu" "k8s" {
  accelerator      = "kvm"
  cd_files         = ["./cloud-init/*"]
  cd_label         = "cidata"
  disk_compression = true
  disk_image       = true
  disk_interface   = "virtio-scsi"
  disk_size        = "50G" # Size in MB

  headless     = true
  iso_checksum = "file:https://cloud-images.ubuntu.com/minimal/daily/${var.ubuntu_version}/current/SHA256SUMS"
  iso_url      = "https://cloud-images.ubuntu.com/minimal/daily/${var.ubuntu_version}/current/${var.ubuntu_version}-minimal-cloudimg-amd64.img"

  output_directory = "output-${var.ubuntu_version}"
  format           = "qcow2"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  ssh_password     = "ubuntu"
  ssh_username     = "ubuntu"
  vm_name          = var.final_image_name

  qemu_binary = "/usr/bin/qemu-system-amd64"
  qemuargs = [
    ["-m", "4096"],
    ["-smp", "2"],
    ["-serial", "mon:stdio"],
  ]
}
