basename = "generic"

image                          = "~/ISOs/ubuntu-20.04-server-cloudimg-amd64.img"
cloud_init_network_config_file = "cloud_init_network-config.yaml"

node_count      = 1
cloud_init_file = "cloud_init.yaml"
memory          = "2048"
vcpu            = 1
network         = "default"

storage_pool   = "default"
storage_format = "qcow2"

ssh_privkey = "~/.ssh/regular_id_rsa"
ssh_user    = "regular"
