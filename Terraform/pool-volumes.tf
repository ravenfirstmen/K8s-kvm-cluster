resource "libvirt_pool" "cluster" {
  name = "${var.cluster_name}-pool"
  type = "dir"
  target {
    path = "/Work/KVM/pools/${var.cluster_name}"
  }
}
