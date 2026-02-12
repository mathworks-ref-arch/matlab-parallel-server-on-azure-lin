#!/usr/bin/env bash
#
# Copyright 2024 The MathWorks, Inc.

# Exit on any failure, treat unset substitution variables as errors
set -euo pipefail

# Configure POLYSPACE_ROOT directory
sudo mkdir -p "${POLYSPACE_ROOT}"
sudo chmod -R 755 "${POLYSPACE_ROOT}"

# Install and setup mpm.
# https://github.com/mathworks-ref-arch/matlab-dockerfile/blob/main/MPM.md
cd /tmp
sudo apt-get -qq install \
  unzip \
  wget \
  ca-certificates
sudo wget --no-verbose https://www.mathworks.com/mpm/glnxa64/mpm
sudo chmod +x mpm

# If a source URL is provided, then use it to install MATLAB and toolboxes.
release_arguments=""
source_arguments=""
if [[ -n "${MATLAB_SOURCE_LOCATION}" ]]; then
  # Setup source for MATLAB installation
  sudo chmod +x /var/tmp/config/matlab/setup-matlab-source.sh
  /var/tmp/config/matlab/setup-matlab-source.sh mount "${MATLAB_SOURCE_LOCATION}" "MATLABFILESHAREUSERNAME" "MATLABFILESHAREPASSWORD" "${AZURE_KEY_VAULT}"

  # Setup appropriate source flag to use with mpm
  source_arguments="--source /mnt/${MATLAB_SOURCE_LOCATION}/dvd/archives"
else
  release_arguments="--release ${RELEASE}"
fi

# Run mpm to install Polyspace in the POLYSPACE_PRODUCTS variable
# into the target location. The mpm installation is deleted afterwards.
# The POLYSPACE_PRODUCTS variable should be a space separated list of products, with no surrounding quotes.
# Use quotes around the destination argument if it contains spaces.
sudo ./mpm install \
  ${release_arguments} \
  ${source_arguments} \
  --destination="${POLYSPACE_ROOT}" \
  --products ${POLYSPACE_PRODUCTS} \
  || (echo "MPM Installation Failure. See below for more information:" && cat /tmp/mathworks_root.log && exit 1)

sudo rm -f mpm /tmp/mathworks_root.log

# If a source location for installation was provided, delete related files and folders after install.
if [[ -n "${MATLAB_SOURCE_LOCATION}" ]]; then
    /var/tmp/config/matlab/setup-matlab-source.sh unmount "${MATLAB_SOURCE_LOCATION}"
fi

# Point MATLAB Parallel Server at polyspace install
sudo sed -i "s|# POLYSPACE_SERVER_ROOT=/usr/local/.*|POLYSPACE_SERVER_ROOT=${POLYSPACE_ROOT}|" ${MATLAB_ROOT}/toolbox/parallel/bin/mjs_polyspace.conf

