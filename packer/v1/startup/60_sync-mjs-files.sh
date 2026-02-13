#!/usr/bin/env bash

# Copyright 2022-2024 The MathWorks, Inc.

PS4='+ [\d \t] '
set -x

FILE_SHARE_NAME='shared'
FILE_SHARE_FOLDER='cluster'

if [[ ! -d "${SECURITY_ROOT}" ]]; then
    mkdir -p "${SECURITY_ROOT}"
    chmod 700 "${SECURITY_ROOT}"
fi

# Create shared secret file and set MATLAB client verification
# https://www.mathworks.com/help/matlab-parallel-server/set-matlab-job-scheduler-cluster-security.html
if [[ "${NODE_TYPE}" == 'HEADNODE' ]]; then

    MJS_HOSTNAME=${HEADNODE_HOSTNAME}

    echo "===Creating secret and profile==="
    PROFILE_FILE="/tmp/${JOB_MANAGER_NAME}.mlsettings"

    cd "${MATLAB_ROOT}/toolbox/parallel/bin" || exit 1
    if [[ ! -f "${SECRET_FILE}" ]] || [[ ! -f "${CERT_FILE}" ]]; then
        ./createSharedSecret -file "${SECRET_FILE}"
        ./generateCertificate -secretfile "${SECRET_FILE}" -certfile "${CERT_FILE}"
    fi

    ./createProfile -name "${JOB_MANAGER_NAME}" -host "${MJS_HOSTNAME}" -certfile "${CERT_FILE}" -outfile "${PROFILE_FILE}"

    echo "===Uploading files to File Share==="
    # Creating File share if we cannot find it in the storage account
    if [[ $(az storage share exists --name "${FILE_SHARE_NAME}" --output tsv) == "False" ]]; then
        echo "Creating file share: ${FILE_SHARE_NAME}"
        if [[ $(az storage share create --name "${FILE_SHARE_NAME}" --quota 100 --output tsv) == "False" ]]; then
            echo "Failed to create file share."
            exit 1
        fi
    else
        echo "Using existing file share: ${FILE_SHARE_NAME}"
    fi
    az storage directory create --share-name "${FILE_SHARE_NAME}" --name "${FILE_SHARE_FOLDER}"

    az storage file upload --share-name "${FILE_SHARE_NAME}" --path "${FILE_SHARE_FOLDER}" --source "${SECRET_FILE}"
    az storage file upload --share-name "${FILE_SHARE_NAME}" --path "${FILE_SHARE_FOLDER}" --source "${PROFILE_FILE}"
    az storage file upload --share-name "${FILE_SHARE_NAME}" --path "${FILE_SHARE_FOLDER}" --source "${CERT_FILE}"

    # Upload default admin password if present
    if [[ -f "${MJS_ADMIN_PASSWORD_FILE}" ]]; then
        az storage file upload --share-name "${FILE_SHARE_NAME}" --path "${FILE_SHARE_FOLDER}" --source "${MJS_ADMIN_PASSWORD_FILE}"
    fi

else

    echo "===Retrieving secret from File Share==="
    # Wait for up to 10 minutes for the shared secret
    # to appear before giving up.
    TIMEOUT=600
    START=$(date -u +%s)
    while [[ $(az storage file exists --share-name "${FILE_SHARE_NAME}" --path "${FILE_SHARE_FOLDER}/secret" --output tsv) == "False" ]]; do
        sleep 1s
        if (($(date -u +%s) - START > TIMEOUT)); then
            echo "The shared secret was not found in ${STORAGE_NAME}/${FILE_SHARE_NAME}/${FILE_SHARE_FOLDER} within ${TIMEOUT} seconds."
            exit 1
        fi
    done

    az storage file download --share-name "${FILE_SHARE_NAME}" --path "${FILE_SHARE_FOLDER}/secret" --dest "${SECRET_FILE}"

fi
