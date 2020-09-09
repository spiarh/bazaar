#!/usr/bin/env bash

for disk in b c d e f; do
  dd if=/dev/zero of=/dev/sd$disk bs=4096 count=1 oflag=direct
  dd if=/dev/zero of=/dev/sd$disk bs=512 count=34 oflag=direct
  dd if=/dev/zero of=/dev/sd$disk bs=512 count=33 seek=$((`blockdev --getsz /dev/sd$disk` - 33)) oflag=direct
  wipefs -f -a /dev/sd$disk
  sgdisk -Z /dev/sd$disk
  parted -s /dev/sd$disk print free
done
