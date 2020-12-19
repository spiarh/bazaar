#!/usr/bin/env bash

set -eu

NET_NAME="${1:-default}"

virsh net-destroy "$NET_NAME"
virsh net-start "$NET_NAME"

VMS=$(virsh list | tail -n +3 | head -n -1 | awk '{ print $2; }')

for vm in $VMS ; do
  domiflist=$(virsh domiflist "$vm" | sed -n 3p)
  vnet0_net=$(echo "$domiflist" | awk '{ print $3; }')

  if [[ $vnet0_net == "$NET_NAME" ]]; then
    echo "$vm have an interface (vmnet0) in $NET_NAME network"
    mac_addr=$(echo "$domiflist" |grep -o -E "([0-9a-f]{2}:){5}([0-9a-f]{2})")
    net_model=$(echo "$domiflist" | awk '{ print $4; }')
    virsh detach-interface "$vm" network --mac "$mac_addr" && sleep 3
    virsh attach-interface "$vm" network "$NET_NAME" --mac "$mac_addr" --model "$net_model"
  else
    echo "$vm does not have an interface (vmnet0) in $NET_NAME network"
  fi
done
