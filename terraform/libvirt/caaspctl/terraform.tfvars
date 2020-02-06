basename = "caaspctl"

image = "/home/lcavajani/ISOs/SLES15-SP1-JeOS-RC1-with-fixed-kernel-default.qcow2"

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

# define the repositories to use
repositories = [
  {
    caasp_40_devel_sle15sp1 = "http://download.suse.de/ibs/Devel:/CaaSP:/4.0/SLE_15_SP1/"
  },
  {
    sle15sp1_pool = "http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/GA/standard/"
  },
  {
    sle15sp1_update = "http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update/standard/"
  },
  {
    sle15_pool = "http://download.suse.de/ibs/SUSE:/SLE-15:/GA/standard/"
  },
  {
    sle15_update = "http://download.suse.de/ibs/SUSE:/SLE-15:/Update/standard/"
  },
  {
    suse_ca = "http://download.suse.de/ibs/SUSE:/CA/SLE_15_SP1/"
  }
]

packages = [
  "ca-certificates-suse",
  "kubernetes-kubeadm",
  "kubernetes-kubelet",
  "kubernetes-client"
]

## ssh keys to inject into all the nodes
#authorized_keys = [
#  ""
#]
