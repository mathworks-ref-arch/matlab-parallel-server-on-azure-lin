#!/usr/bin/env bash

# Copyright 2024-2025 The MathWorks, Inc.

# Exit on any failure
set -eou pipefail

# Initialise apt
sudo apt-get -y update
sudo DEBIAN_FRONTEND=noninteractive apt-get \
  -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  upgrade

# Ensure essential utilities are installed
sudo apt-get -y install gcc
sudo apt-get -y install wget
sudo apt-get -y install make

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install jq
sudo apt-get install jq -y

# Install xq
# https://github.com/sibprogrammer/xq
curl -sSL https://bit.ly/install-xq | sudo bash

# Disable Open Source nVidia Nouveau driver, if present.
DISABLE_NOUVEAU_FILE="disable_nouveau_driver.conf"
MODPROBE_TREE="/etc/modprobe.d/"

echo blacklist amd76x_edac > /tmp/${DISABLE_NOUVEAU_FILE}
echo blacklist vga16fb >> /tmp/${DISABLE_NOUVEAU_FILE}
echo blacklist rivafb >> /tmp/${DISABLE_NOUVEAU_FILE}
echo blacklist nvidiafb >> /tmp/${DISABLE_NOUVEAU_FILE}
echo blacklist rivatv >> /tmp/${DISABLE_NOUVEAU_FILE}
echo blacklist nouveau >> /tmp/${DISABLE_NOUVEAU_FILE}
echo blacklist lbm-nouveau >> /tmp/${DISABLE_NOUVEAU_FILE}
echo options nouveau modeset=0  >> /tmp/${DISABLE_NOUVEAU_FILE}
echo alias nouveau off  >> /tmp/${DISABLE_NOUVEAU_FILE}
echo alias lbm-nouveau off  >> /tmp/${DISABLE_NOUVEAU_FILE}
sudo mv /tmp/${DISABLE_NOUVEAU_FILE} ${MODPROBE_TREE}/
sudo chown root:root  ${MODPROBE_TREE}/${DISABLE_NOUVEAU_FILE}
sudo chmod 755  ${MODPROBE_TREE}/${DISABLE_NOUVEAU_FILE}
sudo update-initramfs -u

# Install nvidia-driver
sudo apt-get -y install --no-install-recommends nvidia-driver-${NVIDIA_DRIVER_VERSION}-server

# Install cifs package for mounting the FileShare if it is missing.
# This is needed because of a recent bug in Azure's Ubuntu 22.04 which hopefully should get resolved in future.
# The issue details can be found here: https://learn.microsoft.com/en-us/answers/questions/1410701/linux-image-6-2-0-1016-azure-cifs-is-not-supported
# The requirement is to have the cifs package version match the current kernel version.
check_package_exists() {
    package_name=$1
    sudo apt-get update > /dev/null 2>&1
    apt-cache search "^${package_name}$" | grep -q "${package_name}"
    return $?
}

# Check if CIFS is installed
if ! modinfo cifs &> /dev/null; then
    # Get current kernel version
    kernel_version=$(uname -r)

    # Define the package name
    package_name="linux-modules-extra-${kernel_version}"

    # Check if the package exists
    if check_package_exists "$package_name"; then
        echo "Installing package: ${package_name}"
        sudo apt-get install -y "$package_name"
    else
        echo "Package ${package_name} not available."
        exit 1
    fi
else
    echo "CIFS module is already installed."
fi
