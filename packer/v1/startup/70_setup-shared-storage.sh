#!/usr/bin/env bash

# Copyright 2024 The MathWorks, Inc.

PS4='+ [\d \t] '
set -x

# This script configures the shared storage similar to:
# https://www.mathworks.com/help/cloudcenter/ug/cluster-file-system-and-storage.html


PERSISTED_FILESHARE_NAME="persisted"
PERSISTED_FILESHARE_MOUNT_PATH="/shared/persisted"
TEMPORARY_FILESHARE_NAME="tmp"
TEMPORARY_FILESHARE_MOUNT_PATH="/shared/tmp"

#-------------------------------------------------- Setup Persisted Storage --------------------------------------------------#

mkdir -p /etc/smbcredentials

# Create credentials file if it doesn't exist
cred_file="/etc/smbcredentials/sa_cred_file.cred"
if [[ ! -f "$cred_file" ]]; then
    set +x
    (bash -c "echo \"username=${AZURE_STORAGE_ACCOUNT}\" >> $cred_file")
    (bash -c "echo \"password=${AZURE_STORAGE_KEY}\" >> $cred_file")
    set -x
    echo "Credential file created."
fi

# Mount persisted file share if it exists
if [[ $(az storage share exists --name "${PERSISTED_FILESHARE_NAME}" --output tsv) == "True" ]]; then

    echo "Persisted file share exists."
    mkdir -p "${PERSISTED_FILESHARE_MOUNT_PATH}"

    # Mount the persisted fileshare on this instance if not already mounted
    mountpoint -q "${PERSISTED_FILESHARE_MOUNT_PATH}"
    if [[ $? -ne 0 ]]; then
        mount -t cifs "//${AZURE_STORAGE_ACCOUNT}.file.core.windows.net/${PERSISTED_FILESHARE_NAME}" "${PERSISTED_FILESHARE_MOUNT_PATH}" -o credentials=$cred_file,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30
    fi
else
    echo "Persisted file share does not exist."
fi

#-------------------------------------------------- Setup Temporary Storage --------------------------------------------------#

# Create TEMPORARY_FILESHARE_MOUNT_PATH
mkdir -p "${TEMPORARY_FILESHARE_MOUNT_PATH}"

if [[ "${NODE_TYPE}" == "HEADNODE" ]]; then
    # Creating temporary file share if it does not exist in the storage account
    if [[ $(az storage share exists --name "${TEMPORARY_FILESHARE_NAME}" --output tsv) == "False" ]]; then
        echo "Creating file share: ${TEMPORARY_FILESHARE_NAME}"
        if [[ $(az storage share create --name "${TEMPORARY_FILESHARE_NAME}" --quota 100 --output tsv) == "False" ]]; then
            echo "Failed to create file share."
        fi
    else
        echo "Using existing file share: ${TEMPORARY_FILESHARE_NAME}"
    fi
fi

# Mount the temporary fileshare on each instance if not already mounted

# Calculate the end time 10 minutes from now
end=$((SECONDS+600))

while true; do
    # Check if the mount point is already mounted
    mountpoint -q "${TEMPORARY_FILESHARE_MOUNT_PATH}"
    if [[ $? -eq 0 ]]; then
        echo "Storage is already mounted."
        break
    else
        # Attempt to mount the storage
        mount -t cifs "//${AZURE_STORAGE_ACCOUNT}.file.core.windows.net/${TEMPORARY_FILESHARE_NAME}" "${TEMPORARY_FILESHARE_MOUNT_PATH}" -o credentials=$cred_file,dir_mode=0777,file_mode=0777,serverino,nosharesock,actimeo=30
        # Check if the mount was successful
        if [[ $? -eq 0 ]]; then
            echo "Storage mounted successfully."
            break
        else
            echo "Failed to mount storage. Retrying in 3 seconds..."
            sleep 3
        fi
    fi
    # Check if 10 minutes have passed
    if [[ $SECONDS -ge $end ]]; then
        echo "Timeout reached. Failed to mount storage within 10 minutes."
        break
    fi
done
