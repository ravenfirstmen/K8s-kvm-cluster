variable "ubuntu_version" {
  type    = string
  default = "noble"
}


variable "volume_pool" {
  type    = string
  default = "Ubuntu24.04"
}

variable "final_image_name" {
  type    = string
  default = "Ubuntu-24.04-LTS-With-K8s.img"
}

variable "k8s_version" {
  type    = string
  default = "1.32.7"
}
