basename = "generic"

image                          = "~/ISOs/ubuntu-20.04-server-cloudimg-amd64.img"
cloud_init_network_config_file = "cloud_init_network-config.yaml"

master_count           = 1
master_cloud_init_file = "cloud_init.yaml"
master_memory          = "2048"
master_vcpu            = 1
master_network         = "default"

worker_count           = 2
worker_cloud_init_file = "cloud_init.yaml"
worker_memory          = "2048"
worker_vcpu            = 1
worker_network         = "default"

storage_pool   = "default"
storage_format = "qcow2"

ssh_privkey = "~/.ssh/regular_id_rsa"
ssh_user    = "regular"
