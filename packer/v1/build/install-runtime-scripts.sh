#!/usr/bin/env bash

# Copyright 2023-2026 The MathWorks, Inc.

# Exit on any failure, treat unset substitution variables as errors
set -euxo pipefail

# Create folder
sudo mkdir -p /opt/mathworks/

# Install pip
sudo apt-get -qq install python3-pip

# Install mwplatforminterfaces package
sudo cp -R /tmp/runtime/mwplatforminterfaces/ /opt/mathworks/

# Installing dependencies outside of a venv hence the break-system-packages flag (to install system-wide)
sudo PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install -e /opt/mathworks/mwplatforminterfaces
sudo PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install -e '/opt/mathworks/mwplatforminterfaces[azure]'

# Install cluster management package
sudo cp -R /tmp/runtime/cluster_management/ /opt/mathworks/
sudo chmod +x /opt/mathworks/cluster_management/cluster_management.py

# Make idle/busy scripts executable, these are triggered by MJS when it is idle/busy
sudo chmod +x /opt/mathworks/cluster_management/terminationpolicies/mjs_status_scripts/idle
sudo chmod +x /opt/mathworks/cluster_management/terminationpolicies/mjs_status_scripts/busy

# Install spotinstances package
sudo cp -R /tmp/runtime/spotinstances/ /opt/mathworks/
sudo chmod +x /opt/mathworks/spotinstances/handle_instance_interruption.py

# Configure the service and timer.
sudo cp /var/tmp/config/cluster_management/clustermanagement.{service,timer} /etc/systemd/system/
sudo cp /var/tmp/config/spotinstances/spotinstances.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload