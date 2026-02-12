#!/usr/bin/env bash

# Copyright 2024-2026 The MathWorks, Inc.

# Logging Setup
LOG_FILE="/var/log/mathworks/mwstatetag.log"

echo "Logs for this script can be found in: $LOG_FILE"

exec 1>>"$LOG_FILE"
exec 2>&1

PS4='+ [\d \t] '
set -x

TIMEOUT_SECONDS=600
START_TIME=$(date +%s)
TAGS_APPLIED=false

login_to_azure() {
    # Login using managed identity of the VM
    # This script might be executed before Azure 
    # assigns a role to the identity.
    # Hence, retries for 180s is added to avoid failures.

    local delay_seconds=30
    local max_attempts=6
    local attempt=0
    local success=false

    while [ $attempt -lt $max_attempts ]; do
        if az login --identity; then
            success=true
            break
        else
            echo "Failed to log in using managed identity. Attempt $((attempt + 1)) of $max_attempts."
            attempt=$((attempt + 1))
            if [ $attempt -lt $max_attempts ]; then
                echo "Waiting for $delay_seconds seconds before retrying az login..."
                sleep $delay_seconds
            fi
        fi
    done

    if [ "$success" = false ]; then
        echo "Failed to log in using managed identity after $max_attempts attempts."
        exit 1
    fi
}

apply_tags() {
    local tag_key_value=$1
    login_to_azure
    # SUBSCRIPTION_ID and RESOURCE_ID are set in the current environment
    # by startup/.env file
    az account set --subscription "${SUBSCRIPTION_ID}"
    if az tag update --resource-id "${RESOURCE_ID}" --operation Merge --tags "${tag_key_value}"; then
        TAGS_APPLIED=true
        echo "Tags successfully applied."
    else
        echo "Failed to apply tags."
        return 1
    fi
    az logout
}

get_node_status_property() {
    local property=$1
    local node_status_output
    local value

    node_status_output=$("${MATLAB_ROOT}/toolbox/parallel/bin/nodestatus" -json) || { echo "Failed to get node status."; exit 1; }
    value=$(echo "${node_status_output}" | jq -r --arg property "$property" '.jobManagers[0][$property]')
    echo "${value}"
}

calculate_elapsed_time() {
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
}

if [[ "${NODE_TYPE}" != "HEADNODE" ]]; then
    exit 0
fi

calculate_elapsed_time
while [[ "${ELAPSED_TIME}" -lt "${TIMEOUT_SECONDS}" ]]; do
    status=$(get_node_status_property "status") || exit $?
    
    if [[ "${status}" != "running" ]]; then
        echo "JobManager's status is not 'running'. Current status: ${status}"
        sleep 10
        calculate_elapsed_time
        continue
    fi

    #if autoscaling is not enabled, check for atleast one worker
    if [[ "${ENABLE_AUTOSCALING}" == "No" && $(get_node_status_property "numWorkers") -lt 1 ]]; then
        sleep 10
        calculate_elapsed_time
        continue
    fi

    if apply_tags "mw-state=ready"; then 
        break
    else 
        sleep 10
        calculate_elapsed_time
    fi
done

if [[ "${ELAPSED_TIME}" -ge "${TIMEOUT_SECONDS}" && "${TAGS_APPLIED}" == false ]]; then
    echo "Timeout reached after ${TIMEOUT_SECONDS} seconds without applying tags."
    apply_tags "mw-state=timeout"
fi
