#!/usr/bin/env bash

# Copyright 2024-2026 The MathWorks, Inc.

# This script is supposed to run only in the Headnode of the cluster.

set -u

TEMPORARY_FILESHARE_NAME="tmp"
MAX_RETRIES=3
RETRY_INTERVAL=3  # time in seconds

# Load the existing storage account creds
source /etc/smbcredentials/sa_cred_file.cred
source /etc/profile.d/node-type.sh

# Function to delete the Temporary FileShare
delete_file_share() {
    az storage share delete \
        --name "${TEMPORARY_FILESHARE_NAME}" \
        --account-name "${username}" \
        --account-key "${password}" \
        --output tsv
}

# Function to check if the Temporary FileShare exists
file_share_exists() {
    [[ $(az storage share exists \
        --name "${TEMPORARY_FILESHARE_NAME}" \
        --account-name "${username}" \
        --account-key "${password}" \
        --output tsv) == "True" ]]
}

# Delete the Temporary FileShare when the Headnode is shutting down.
for (( i=0; i<MAX_RETRIES; i++ )); do
    delete_file_share
    sleep ${RETRY_INTERVAL}
    if file_share_exists; then
        echo "Retrying to delete file share. Attempt $((i+1)) of ${MAX_RETRIES}."
    else
        echo "Successfully deleted the file share: ${TEMPORARY_FILESHARE_NAME}"
        break
    fi
done

if file_share_exists; then
    echo "Failed to delete file share after ${MAX_RETRIES} attempts."
fi
