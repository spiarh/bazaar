basename = "multi"
image = "/home/lcavajani/ISOs/Fedora-Cloud-Base-31-1.9.x86_64.qcow2"
node_count = 3

cloud_init_file = "cloud_init.yaml"
cloud_init_network_config_file = "cloud_init_network-config.yaml"

storage_pool = "default"
storage_format = "qcow2"
network = "default"

memory = "2048"
vcpu = 1

ssh_privkey = "/home/lcavajani/.ssh/regular_id_rsa"
ssh_user = "regular"
