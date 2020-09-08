basename = "standalone"
image    = "/srv/ISOs/ubuntu-20.04-server-cloudimg-amd64.img"

cloud_init_file                = "cloud_init.yaml"
cloud_init_network_config_file = "cloud_init_network-config.yaml"

storage_format = "qcow2"
storage_pool   = "default"
network        = "default"

memory = "2048"
vcpu   = 1

ssh_privkey = "/home/lcavajani/.ssh/regular_id_rsa"
ssh_user    = "regular"
