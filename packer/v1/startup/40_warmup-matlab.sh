#!/usr/bin/env bash

# Copyright 2022-2024 The MathWorks, Inc.

PS4='+ [\d \t] '
set -x

if [[ -n ${MATLAB_ROOT} ]]; then
    ${MATLAB_ROOT}/bin/glnxa64/MATLABStartupAccelerator 64 ${MATLAB_ROOT} /usr/local/etc/msa/msa.ini /var/log/msa.log
    echo 'Warm up done.'
fi

# assigne latest timestamp to toolbox cache to ensure it is picked up by MATLAB
touch "${MATLAB_ROOT}/toolbox/local/toolbox_cache-glnxa64.xml"
