# network

variable "network_zone1_cidr" {
  type    = string
  default = "192.168.180.0/24"
}

variable "network_zone2_cidr" {
  type    = string
  default = "192.168.190.0/24"
}

variable "network_domain" {
  type    = string
  default = "k8s.local"
}

# Volumes
variable "base_volume_pool" {
  type    = string
  default = "Ubuntu24.04"
}

variable "base_volume_name" {
  type    = string
  default = "Ubuntu-24.04-LTS-With-K8s.img"
}

variable "k8s_version" {
  type    = string
  default = "1.32.7"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name used as prefix for the machine names"
  default     = "k8scluster"
}

variable "zone1_n_nodes" {
  type        = number
  description = "number of nodes"
  default     = 3
}

variable "zone2_n_nodes" {
  type        = number
  description = "number of nodes"
  default     = 0
}

variable "virtual_memory_worker_nodes" {
  type        = number
  default     = 4096
  description = "Virtual RAM in MB for worker nodes"
}

variable "virtual_cpus_worker_nodes" {
  type        = number
  default     = 2
  description = "Number of virtual CPUs for worker nodes"
}

variable "virtual_memory_controller" {
  type        = number
  default     = 4096
  description = "Virtual RAM in MB for controller"
}

variable "virtual_cpus_controller" {
  type        = number
  default     = 2
  description = "Number of virtual CPUs for controller"
}

variable "virtual_cpus_loadbalancer" {
  type        = number
  default     = 1
  description = "Number of virtual CPUs for loadbalancer"
}

variable "virtual_memory_loadbalancer" {
  type        = number
  default     = 1024
  description = "Virtual RAM in MB for loadbalancer"
}
