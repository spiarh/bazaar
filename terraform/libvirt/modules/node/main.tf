variable "role" {
}

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

##############
### VOLUME ###
##############

resource "libvirt_volume" "node" {
  name   = "vol-${var.role}-${var.basename}-${count.index}"
  source = pathexpand(var.image)
  count  = var.node_count
  pool   = var.storage_pool
  format = var.storage_format
}

##################
### CLOUD-INIT ###
##################

data "template_file" "user_data" {
  template = file(pathexpand(var.cloud_init_file))
}

data "template_file" "network_config" {
  template = file(pathexpand(var.cloud_init_network_config_file))
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "cloud-init-${var.role}-${var.basename}.iso"
  pool           = var.storage_pool
  user_data      = data.template_file.user_data.rendered
  #network_config = data.template_file.network_config.rendered
}

##########
### VM ###
##########

resource "libvirt_domain" "node" {
  name   = "${var.role}-${var.basename}-${count.index}"
  memory = var.memory
  vcpu   = var.vcpu
  count  = var.node_count

  cloudinit = libvirt_cloudinit_disk.cloud_init.id

  network_interface {
    network_name   = var.network
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
    volume_id = element(libvirt_volume.node.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

resource "null_resource" "node" {
  count = var.node_count

  connection {
    type = "ssh"
    host = element(
      libvirt_domain.node.*.network_interface.0.addresses.0,
      count.index,
    )
    user        = var.ssh_user
    agent       = "false"
    private_key = fileexists(var.ssh_privkey) ? file(var.ssh_privkey) : null
  }

  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.role}-${var.basename}-${count.index}",
      "cloud-init status --wait > /dev/null",
    ]
  }
}

output "ip_nodes" {
  value = libvirt_domain.node.*.network_interface.0.addresses
}
