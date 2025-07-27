
build {

  sources = [
    "source.qemu.k8s"
  ]

  provisioner "shell" {
    inline = [
      "/usr/bin/cloud-init status --wait",
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
    ]
  }

  provisioner "shell" {
    scripts = ["./files/packages/00-install-utils.sh"]
  }

  provisioner "shell" {
    environment_vars = ["INSTALLABLE_K8S_VERSION=${var.k8s_version}"]
    script           = "./files/packages/01-install-k8s-dependencies.sh"
  }

  provisioner "shell" {
    scripts = ["./files/packages/02-install-haproxy.sh"]
  }

  provisioner "shell" {
    environment_vars = ["INSTALLABLE_K8S_VERSION=${var.k8s_version}"]
    scripts          = ["./files/scripts/01-configure-os-for-k8s.sh"]
  }

  provisioner "shell" {
    scripts = [
      "./files/scripts/99-clean-image.sh"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }

}
