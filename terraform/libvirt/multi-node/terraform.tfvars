basename = "pharos"
image = "/home/lcavajani/ISOs/openSUSE-Leap-15.0-OpenStack.x86_64-0.0.4-Buildlp150.12.45.qcow2"
#image = "/home/lcavajani/ISOs/openSUSE-Leap-15.0-JeOS.x86_64-15.0.1-kvm-and-xen-Snapshot20.122.qcow2"
count = 3

cloud_init_file = "cloud_init.yaml"
cloud_init_network_config_file = "cloud_init_network-config.yaml"

storage_pool = "default"
storage_format = "qcow2"
network = "default"

memory = "2048"
vcpu = 1

ssh_privkey = "/home/lcavajani/.ssh/regular_id_rsa"
ssh_user = "root"
