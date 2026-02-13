#!/usr/bin/env bash
#
# Copyright 2024-2026 The MathWorks, Inc.

# Exit on any failure, treat unset substitution variables as errors
set -euo pipefail

# Sets up sproot to force mpm to install SPKGS in a custom location
# In Azure, since the username is dynamic, we install spkgs in a user-agnostic location
DEFAULT_SPKG_ROOT="${MATLAB_ROOT}/SupportPackages/${RELEASE}"
sudo mkdir -p "${DEFAULT_SPKG_ROOT}"

if [[ $RELEASE == 'R2024b' ]]; then
    # For MATLAB R2024b, execute both commands
    sudo "${MATLAB_ROOT}/bin/glnxa64/sprootsettingwriter" -matlabroot ${MATLAB_ROOT} -sproot ${DEFAULT_SPKG_ROOT}
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><SupportPackageRootSettings><Setting name=\"sproot\">${DEFAULT_SPKG_ROOT}</Setting></SupportPackageRootSettings>" | sudo tee "${MATLAB_ROOT}/toolbox/local/supportpackagerootsetting.xml" > /dev/null
elif [[ $RELEASE > 'R2024b' ]]; then
    # For MATLAB R2025a and later, use the new sproot setting writer
    sudo "${MATLAB_ROOT}/bin/glnxa64/sprootsettingwriter" -matlabroot ${MATLAB_ROOT} -sproot ${DEFAULT_SPKG_ROOT}
else
    # For MATLAB versions before R2024b, use the XML file method
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><SupportPackageRootSettings><Setting name=\"sproot\">${DEFAULT_SPKG_ROOT}</Setting></SupportPackageRootSettings>" | sudo tee "${MATLAB_ROOT}/toolbox/local/supportpackagerootsetting.xml" > /dev/null
fi
