variable "basename" {
}

variable "image" {
}

variable "cloud_init_file" {
}

variable "cloud_init_network_config_file" {
}

variable "storage_pool" {
}

variable "storage_format" {
}

variable "network" {
}

variable "memory" {
}

variable "vcpu" {
}

variable "ssh_privkey" {
}

variable "ssh_user" {
}

# Povider
provider "libvirt" {
  uri = "qemu:///system"
}

###############
### VOLUMES ###
###############

# adapt the build number 
resource "libvirt_volume" "node" {
  name   = "vol-${var.basename}"
  source = var.image
  pool   = var.storage_pool
  format = var.storage_format
}

##################
### CLOUD-INIT ###
##################

data "template_file" "user_data" {
  template = file(var.cloud_init_file)
}

data "template_file" "network_config" {
  template = file(var.cloud_init_network_config_file)
}


resource "libvirt_cloudinit_disk" "cloud_init" {
  name           = "cloud_init_${var.basename}.iso"
  pool           = var.storage_pool
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}

##########
### VM ###
##########

# Create the machine
resource "libvirt_domain" "node" {
  name   = var.basename
  memory = var.memory
  vcpu   = var.vcpu

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
    volume_id = libvirt_volume.node.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

resource "null_resource" "node" {

  connection {
    type        = "ssh"
    host        = libvirt_domain.node.network_interface.0.addresses.0
    user        = var.ssh_user
    agent       = "true"
    private_key = fileexists(var.ssh_privkey) ? file(var.ssh_privkey) : null
  }

  # This ensures the VM is booted and SSH'able
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.basename}",
    ]
  }
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain
output "ip_nodes" {
  value = [libvirt_domain.node.network_interface.0.addresses]
}

