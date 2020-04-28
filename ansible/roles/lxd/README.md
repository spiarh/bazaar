```
config:
  boot.autostart: "true"
  linux.kernel_modules: ip_tables,ip6_tables,netlink_diag,nf_nat,overlay,br_netfilter,vxlan,cls_bpf,xt_bpf,bpfilter
  raw.lxc: |-
    lxc.apparmor.profile=unconfined
    lxc.cap.drop=
    lxc.cgroup.devices.allow=a
    lxc.mount.auto=proc:rw sys:rw cgroup:rw
    lxc.mount.entry = /sys/fs/bpf sys/fs/bpf none bind,rslave 0 0
    lxc.mount.entry = /boot boot none bind,rslave 0 0
  security.nesting: "true"
  security.privileged: "true"
  user.user-data: |
    #cloud-config
    users:
      - name: root
        ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHUkbmn1u0EPaf1Nqnx8KSn9sfcgLxsaDSyPy+xmHJ1
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYc8ZQW4ii6fkEhI36Si8lu91xYYU17xtWCG4smuM1n
description: Kubernetes Nodes profile
devices:
  aadisable:
    path: /dev/kmsg
    source: /dev/kmsg
    type: unix-char
  eth0:
    name: eth0
    nictype: bridged
    parent: lxdbrk8s
    type: nic
  lib-modules:
    path: /lib/modules
    readonly: "true"
    source: /lib/modules
    type: disk
  linux-headers:
    path: /usr/src
    readonly: "true"
    source: /usr/src
    type: disk
  root:
    path: /
    pool: default
    type: disk
name: k8s
used_by: []
```
