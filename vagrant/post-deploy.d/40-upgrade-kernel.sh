#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

kernel_updated_file=/root/kernel-updated
if [ ! -f $kernel_updated_file ] ; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install linux-generic-lts-vivid -y
  old_kernel_version=$(uname -r)
  new_kernel_version=$(find /boot/vmlinuz-3.19* | sed -E 's/.*(3.19)/\1/')
  sed -i'' "s/$old_kernel_version/$new_kernel_version/g" /boot/grub/menu.lst
  update-grub
  touch $kernel_updated_file
  reboot
fi
