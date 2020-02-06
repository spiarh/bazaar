basename = "pharos"

image = "/home/lcavajani/ISOs/bionic-server-cloudimg-amd64_resized.img"

master_count = 1
master_cloud_init_file = "cloud_init.yaml"
master_memory = "2048"
master_vcpu = 2

worker_count = 2
worker_cloud_init_file = "cloud_init.yaml"
worker_memory = "2048"
worker_vcpu = 1

storage_pool = "default"
storage_format = "qcow2"
network = "default"

ssh_privkey = "/home/lcavajani/.ssh/regular_id_rsa"
