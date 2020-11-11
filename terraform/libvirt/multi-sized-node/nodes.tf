variable "basename" {
}

variable "image" {
}

variable "cloud_init_network_config_file" {
}

variable "master_count" {
}

variable "master_cloud_init_file" {
}

variable "master_memory" {
}

variable "master_vcpu" {
}

variable "master_network" {
}

variable "worker_count" {
}

variable "worker_cloud_init_file" {
}

variable "worker_memory" {
}

variable "worker_vcpu" {
}

variable "worker_network" {
}

variable "storage_pool" {
}

variable "storage_format" {
}

variable "ssh_privkey" {
}

variable "ssh_user" {
}

module "master" {
  source   = "../modules/node"
  role = "master"
  basename = var.basename
  image = var.image
  cloud_init_network_config_file = var.master_cloud_init_file
  node_count = var.master_count
  cloud_init_file = var.master_cloud_init_file
  memory = var.master_memory
  vcpu = var.master_vcpu
  network = var.master_network
  storage_pool = var.storage_pool
  storage_format = var.storage_format
  ssh_privkey = var.ssh_privkey
  ssh_user = var.ssh_user
}

module "worker" {
  source   = "../modules/node"
  role = "worker"
  basename = var.basename
  image = var.image
  cloud_init_network_config_file = var.worker_cloud_init_file
  node_count = var.worker_count
  cloud_init_file = var.worker_cloud_init_file
  memory = var.worker_memory
  vcpu = var.worker_vcpu
  network = var.worker_network
  storage_pool = var.storage_pool
  storage_format = var.storage_format
  ssh_privkey = var.ssh_privkey
  ssh_user = var.ssh_user
}

output "ip_masters" {
  value = flatten(module.master.ip_nodes)
}

output "ip_workers" {
  value = flatten(module.worker.ip_nodes)
}
