#!/usr/bin/env bash

# Copyright 2022-2024 The MathWorks, Inc.

PS4='+ [\d \t] '
set -x

# Make data disk available
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal

FSTYPE=xfs

data_idx=1
for DISK in $(lsblk -dpn -o NAME); do

    echo "${DISK}"
    # Find disks with no file system
    if [[ $(file -bs "${DISK}") == 'data' ]]; then

        echo "Create file system"
        mkfs -t "${FSTYPE}" "${DISK}"
        partprobe "${DISK}"

        echo "Define mount location"
        MOUNTPOINT="/data${data_idx}"
        data_idx=$((data_idx+1))
        
        echo "Mount at ${MOUNTPOINT}"
        mkdir -p "${MOUNTPOINT}"
        mount "${DISK}" "${MOUNTPOINT}"
        chmod 1777 "${MOUNTPOINT}"

        echo "Mount after reboot"
        UUID=$(blkid -o value -s UUID "${DISK}")
        echo "UUID=${UUID} ${MOUNTPOINT} ${FSTYPE} defaults,nofail 0 2" >> /etc/fstab

    fi
done
