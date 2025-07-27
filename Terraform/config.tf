terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.13.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
