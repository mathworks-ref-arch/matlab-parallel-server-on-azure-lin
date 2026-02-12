#!/usr/bin/env bash
#
# Copyright 2022-2024 The MathWorks, Inc.

# Exit on any failure, treat unset substitution variables as errors
set -euo pipefail

sudo mkdir -p /opt/mathworks/
sudo mv /tmp/startup/ /opt/mathworks/
sudo chmod +x /opt/mathworks/startup/*.sh

# Configure the run-userdata service.
sudo cp /var/tmp/config/startup/run-userdata.service  /etc/systemd/system/
