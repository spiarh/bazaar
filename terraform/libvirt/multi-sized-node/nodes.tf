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

# Provider
provider "libvirt" {
  uri = "qemu:///system"
}

###############
### VOLUMES ###
###############

resource "libvirt_volume" "master" {
  name   = "vol-master-${var.basename}-${count.index}"
  source = var.image
  count  = var.master_count
  pool   = var.storage_pool
  format = var.storage_format
}

resource "libvirt_volume" "worker" {
  name   = "vol-worker-${var.basename}-${count.index}"
  source = var.image
  count  = var.worker_count
  pool   = var.storage_pool
  format = var.storage_format
}

##################
### CLOUD-INIT ###
##################

data "template_file" "master_user_data" {
  template = file(var.master_cloud_init_file)
}

resource "libvirt_cloudinit_disk" "master_cloud_init" {
  name           = "cloud-init-master-${var.basename}.iso"
  pool           = var.storage_pool
  user_data      = data.template_file.master_user_data.rendered
  network_config = file(var.cloud_init_network_config_file)
}

data "template_file" "worker_user_data" {
  template = file(var.worker_cloud_init_file)
}

resource "libvirt_cloudinit_disk" "worker_cloud_init" {
  name           = "cloud-init-worker-${var.basename}.iso"
  pool           = var.storage_pool
  user_data      = data.template_file.worker_user_data.rendered
  network_config = file(var.cloud_init_network_config_file)
}

#################
### MASTER VM ###
#################

resource "libvirt_domain" "master" {
  name   = "master-${var.basename}-${count.index}"
  memory = var.master_memory
  vcpu   = var.master_vcpu
  count  = var.master_count

  cloudinit = libvirt_cloudinit_disk.master_cloud_init.id

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
}

resource "null_resource" "master" {
  count = var.master_count

  connection {
    type = "ssh"
    host = element(
      libvirt_domain.master.*.network_interface.0.addresses.0,
      count.index,
    )
    user        = var.ssh_user
    agent       = "false"
    private_key = fileexists(var.ssh_privkey) ? file(var.ssh_privkey) : null
  }

  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname master-${var.basename}-${count.index}",
    ]
  }
}

#################
### WORKER VM ###
#################

resource "libvirt_domain" "worker" {
  name   = "worker-${var.basename}-${count.index}"
  memory = var.worker_memory
  vcpu   = var.worker_vcpu
  count  = var.worker_count

  cloudinit = libvirt_cloudinit_disk.worker_cloud_init.id

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
}

resource "null_resource" "worker" {
  count = var.worker_count

  connection {
    type = "ssh"
    host = element(
      libvirt_domain.worker.*.network_interface.0.addresses.0,
      count.index,
    )
    user        = var.ssh_user
    agent       = "false"
    private_key = file(var.ssh_privkey)
  }

  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname worker-${var.basename}-${count.index}",
    ]
  }
}

output "ip_masters" {
  value = [libvirt_domain.master.*.network_interface.0.addresses]
}

output "ip_workers" {
  value = [libvirt_domain.worker.*.network_interface.0.addresses]
}

