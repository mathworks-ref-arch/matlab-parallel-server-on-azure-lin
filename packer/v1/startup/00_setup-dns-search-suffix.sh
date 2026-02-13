#!/usr/bin/env bash

# Copyright 2025-2026 The MathWorks, Inc.

# Description:
# Configures the default DNS search suffix for Azure Linux VMs using systemd-resolved.
#
# When a custom DNS server is used in an Azure VNET, Azure DHCP assigns the 
# placeholder suffix 'reddog.microsoft.com' as the default domain in the VMs, instead of the actual custom domain.
# This prevents short-name resolution (e.g., when 'ping <hostname>' is run, the OS automatically
# expands this to <hostname>.reddog.microsoft.com, which will always result in an NXDOMAIN answer).
# This script explicitly configures the search domain to enable short-name resolution for hosts within the virtual network.
# For more details, see: https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-name-resolution-for-vms-and-role-instances?tabs=redhat#name-resolution-that-uses-your-own-dns-server

PS4='+ [\d \t] '
set -x

# Setup default DNS search domain, in case a custom DNS server is being used in the Virtual network
if [[ -z "${CUSTOM_DNS_SUFFIX}" ]]; then
    echo "CUSTOM_DNS_SUFFIX environment variable is empty or not set. Skipping DNS configuration."
    exit 0
fi

echo "Setting DNS search suffix to: ${CUSTOM_DNS_SUFFIX}"

# Create systemd-resolved configuration directory
echo "Creating systemd-resolved configuration directory"
mkdir -p /etc/systemd/resolved.conf.d/

# Create custom DNS search configuration
# 'Domains' sets the search suffixes used for short-name lookup
echo "Creating DNS search configuration file"
cat > /etc/systemd/resolved.conf.d/custom-search.conf << EOF
[Resolve]
Domains=$CUSTOM_DNS_SUFFIX
EOF

# Set proper permissions
echo "Set permissions on configuration file"
chmod 644 /etc/systemd/resolved.conf.d/custom-search.conf

# Restart systemd-resolved service to apply changes
echo "Restarting systemd-resolved service"
systemctl restart systemd-resolved

# Wait a moment for the service to restart
sleep 2
