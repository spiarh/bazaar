variable "basename" {
}

variable "image" {
}

variable "admin_count" {
}

variable "admin_cloud_init_file" {
}

variable "admin_memory" {
}

variable "admin_vcpu" {
}

variable "admin_network" {
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

# Provider
provider "libvirt" {
  uri = "qemu:///system"
}

###############
### VOLUMES ###
###############

resource "libvirt_volume" "admin" {
  name   = "vol-admin-${var.basename}-${count.index}"
  source = var.image
  count  = var.admin_count
  pool   = var.storage_pool
  format = var.storage_format
}

resource "libvirt_volume" "master" {
  name   = "vol-master-${var.basename}-${count.index}"
  source = var.image
  count  = var.master_count
  pool   = var.storage_pool
  format = var.storage_format

  depends_on = [libvirt_domain.admin]
}

resource "libvirt_volume" "worker" {
  name   = "vol-worker-${var.basename}-${count.index}"
  source = var.image
  count  = var.worker_count
  pool   = var.storage_pool
  format = var.storage_format

  depends_on = [libvirt_domain.admin]
}

##################
### CLOUD-INIT ###
##################

data "template_file" "admin_user_data" {
  count    = var.admin_count
  template = file(var.admin_cloud_init_file)

  vars = {
    hostname = "admin-${var.basename}-${count.index}"
  }
}

resource "libvirt_cloudinit_disk" "admin_cloud_init" {
  name      = "cloud-init-admin-${var.basename}.iso"
  pool      = var.storage_pool
  user_data = data.template_file.admin_user_data[0].rendered
}

data "template_file" "master_user_data" {
  # needed when 0 master nodes are defined
  count    = var.master_count
  template = file(var.master_cloud_init_file)

  vars = {
    admin_ip = libvirt_domain.admin.network_interface.0.addresses[0]
    hostname = "master-${var.basename}-${count.index}"
  }

  depends_on = [libvirt_domain.admin]
}

resource "libvirt_cloudinit_disk" "master_cloud_init" {
  name      = "cloud-init-master-${var.basename}-${count.index}.iso"
  count     = var.master_count
  pool      = var.storage_pool
  user_data = element(data.template_file.master_user_data.*.rendered, count.index)
}

data "template_file" "worker_user_data" {
  # needed when 0 master nodes are defined
  count    = var.worker_count
  template = file(var.worker_cloud_init_file)

  vars = {
    admin_ip = libvirt_domain.admin.network_interface.0.addresses[0]
    hostname = "worker-${var.basename}-${count.index}"
  }

  depends_on = [libvirt_domain.admin]
}

resource "libvirt_cloudinit_disk" "worker_cloud_init" {
  name      = "cloud-init-worker-${var.basename}-${count.index}.iso"
  count     = var.worker_count
  pool      = var.storage_pool
  user_data = element(data.template_file.worker_user_data.*.rendered, count.index)
}

################
### ADMIN VM ###
################

resource "libvirt_domain" "admin" {
  name   = "admin-${var.basename}-${count.index}"
  memory = var.admin_memory
  vcpu   = var.admin_vcpu

  cloudinit = libvirt_cloudinit_disk.admin_cloud_init.id

  network_interface {
    network_name   = var.admin_network
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.admin[0].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  #
  #
  connection {
    type        = "ssh"
    user        = var.ssh_user
    agent       = "false"
    private_key = file(var.ssh_privkey)
  }

  # This ensures the VM is booted and SSH'able
  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname admin-${var.basename}-${count.index}",
    ]
  }
}

#################
### MASTER VM ###
#################

resource "libvirt_domain" "master" {
  depends_on = [libvirt_domain.admin]
  name       = "master-${var.basename}-${count.index}"
  memory     = var.master_memory
  vcpu       = var.master_vcpu
  count      = var.master_count

  cloudinit = element(libvirt_cloudinit_disk.master_cloud_init.*.id, count.index)

  network_interface {
    network_name   = var.master_network
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.master.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  #
  #
  connection {
    type        = "ssh"
    user        = var.ssh_user
    agent       = "false"
    private_key = file(var.ssh_privkey)
  }

  # This ensures the VM is booted and SSH'able
  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname master-${var.basename}-${count.index}",
    ]
  }
}

#################
### WORKER VM ###
#################

resource "libvirt_domain" "worker" {
  depends_on = [libvirt_domain.admin]
  name       = "worker-${var.basename}-${count.index}"
  memory     = var.worker_memory
  vcpu       = var.worker_vcpu
  count      = var.worker_count

  cloudinit = element(libvirt_cloudinit_disk.worker_cloud_init.*.id, count.index)

  network_interface {
    network_name   = var.worker_network
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.worker.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    agent       = "false"
    private_key = file(var.ssh_privkey)
  }

  # This ensures the VM is booted and SSH'able
  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname worker-${var.basename}-${count.index}",
    ]
  }
}

output "ip_admin" {
  value = [libvirt_domain.admin.*.network_interface.0.addresses]
}

output "ip_masters" {
  value = [libvirt_domain.master.*.network_interface.0.addresses]
}

output "ip_workers" {
  value = [libvirt_domain.worker.*.network_interface.0.addresses]
}

