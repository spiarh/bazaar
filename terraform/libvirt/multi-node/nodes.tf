variable "basename" {
}

variable "image" {
}

variable "cloud_init_network_config_file" {
}

variable "node_count" {
}

variable "cloud_init_file" {
}

variable "memory" {
}

variable "vcpu" {
}

variable "network" {
}

variable "storage_pool" {
}

variable "storage_format" {
}

variable "ssh_privkey" {
}

variable "ssh_user" {
}

module "node" {
  source                         = "../modules/node"
  role                           = "node"
  basename                       = var.basename
  image                          = var.image
  node_count                     = var.node_count
  cloud_init_network_config_file = var.cloud_init_file
  cloud_init_file                = var.cloud_init_file
  memory                         = var.memory
  vcpu                           = var.vcpu
  network                        = var.network
  storage_pool                   = var.storage_pool
  storage_format                 = var.storage_format
  ssh_privkey                    = var.ssh_privkey
  ssh_user                       = var.ssh_user
}

output "ip_nodes" {
  value = flatten(module.node.ip_nodes)
}
