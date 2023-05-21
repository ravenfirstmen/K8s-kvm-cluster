resource "libvirt_pool" "cluster" {
  name = "${var.cluster_name}-pool"
  type = "dir"
  path = "/Work/KVM/pools/${var.cluster_name}"
}

