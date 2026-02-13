#!/usr/bin/env bash

# Copyright 2024-2025 The MathWorks, Inc.

# Exit on any failure
set -e
set -x

# Clear build configuration files
sudo rm -rf /var/tmp/config/

# Clear packer home directory
sudo rm -rf /home/packer/

# Clear SSH host keys
sudo rm -f /etc/ssh/ssh_host_*_key*
# Clear SSH config (including authorized keys)
sudo rm -rf /root/.ssh/

# Reset the system journal logs
sudo rm -rf /var/log/journal/*
sudo systemctl restart systemd-journald


#########  Azure marketplace certification malware fix  #########

# Malware detected on your VHD and the list of filenames includes (Malware detected on your VHD and the list of filenames 
# includes (Image digestId: , File name: pismo.h, Malware Information: avira(malware) sophos(phishing) bitdefender(phishing) 
# ConfirmedMaliciousURL hXXp[:]//www[.]pismoworld[.]org/ (FileType:.h)  (Executable:true)

sudo find /usr/src -type f -name "pismo.h" -exec sed -i '/pismoworld.org/d' {} +

sudo apt-get remove --purge yt-dlp
sudo apt-get autoremove
