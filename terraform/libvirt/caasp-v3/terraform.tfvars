basename = "generic"

image = "/data/SUSE-CaaS-Platform-3.0-for-KVM-and-Xen.x86_64-3.0.0-GM.qcow2"

admin_count = 1
admin_cloud_init_file = "cloud_init_admin.yaml"
admin_memory = "8192"
admin_vcpu = 2
admin_network = "masters"

master_count = 1
master_cloud_init_file = "cloud_init_masters.yaml"
master_memory = "4096"
master_vcpu = 2
master_network = "masters"

worker_count = 2
worker_cloud_init_file = "cloud_init_workers.yaml"
worker_memory = "2048"
worker_vcpu = 1
worker_network = "workers"

storage_pool = "data"
storage_format = "qcow2"

ssh_privkey = "/root/.ssh/id_rsa"
ssh_user = "root"
