variable "source_img_file" {
  type    = string
  default = "/Work/IMG/jammy-server-cloudimg-amd64-52G.img"
}

variable "volume_pool" {
  type    = string
  default = "Ubuntu22.04"
}

variable "final_image_name" {
  type    = string
  default = "Ubuntu-22.04-LTS-With-K8s.qcow2"
}

variable "k8s_version" {
  type    = string
  default = "1.26.4"
}
