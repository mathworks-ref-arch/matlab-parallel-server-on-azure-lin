#!/usr/bin/env bash

# Copyright 2024 The MathWorks, Inc.

# Exit on any failure, treat unset substitution variables as errors
set -eux

# Install delete-tmp-fileshare script and configure run-at-shutdown service
sudo cp -R /tmp/shutdown /opt/mathworks/
sudo chmod +x /opt/mathworks/shutdown/delete-tmp-fileshare.sh
sudo chmod +x /opt/mathworks/shutdown/set-mw-state-down.sh
sudo cp /var/tmp/config/shutdown/run-at-shutdown.service /etc/systemd/system/
sudo systemctl daemon-reload
