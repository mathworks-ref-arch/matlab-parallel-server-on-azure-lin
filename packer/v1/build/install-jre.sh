#!/usr/bin/env bash
#
# Copyright 2026 The MathWorks, Inc.

# Exit on any failure, treat unset substitution variables as errors
set -euo pipefail

# Configuration
JAVA_VERSION="${JAVA_VERSION:-8}"
OS="${OS:-linux}"
ARCH="${ARCH:-x64}"
IMAGE_TYPE="${IMAGE_TYPE:-jre}"
MATLAB_JRE_PATH="${MATLAB_JRE_PATH:-/usr/local/matlab/sys/java/jre/glnxa64/}"
POLYSPACE_JRE_PATH="${POLYSPACE_JRE_PATH:-/usr/local/polyspace/sys/java/jre/glnxa64/}"

API_URL="https://api.adoptium.net/v3/binary/latest/${JAVA_VERSION}/ga/${OS}/${ARCH}/${IMAGE_TYPE}/hotspot/normal/eclipse"

echo "Downloading JRE ${JAVA_VERSION} (${OS}/${ARCH})..."

# Download the binary
FETCH_URL=$(curl -s -w '%{redirect_url}' "${API_URL}")
FILENAME=$(curl -OLs -w '%{filename_effective}' "${FETCH_URL}")

# Verify SHA-256 checksum
echo "Verifying checksum..."
curl -Ls "${FETCH_URL}.sha256.txt" | sha256sum -c --status
echo "Checksum OK"

# Remove existing JRE installs
sudo rm -rf "${MATLAB_JRE_PATH}/jre"
if [ -d "${POLYSPACE_JRE_PATH}" ]; then
  sudo rm -rf "${POLYSPACE_JRE_PATH}/jre"
fi

# Extract and configure
INSTALL_DIR="/opt/java/${JAVA_VERSION}/jre"
sudo mkdir -p "${INSTALL_DIR}"
sudo tar xzf "${FILENAME}" -C "${INSTALL_DIR}" --strip-components=1

# Create softlink for MATLAB and Polyspace
sudo ln -s "${INSTALL_DIR}" "${MATLAB_JRE_PATH}/jre"
if [ -d "${POLYSPACE_JRE_PATH}" ]; then
  sudo ln -s "${INSTALL_DIR}" "${POLYSPACE_JRE_PATH}/jre"
fi

echo "Adoptium JRE ${JAVA_VERSION} installed to ${INSTALL_DIR}"
"${INSTALL_DIR}/bin/java" -version

# Cleanup downloaded ZIP
sudo rm -f "${FILENAME}"
