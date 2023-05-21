packer {
  required_plugins {
    libvirt = {
      version = ">= 0.4.1"
      source  = "github.com/thomasklein94/libvirt"
    }
  }
}
