#!/usr/bin/env bash

# Copyright 2022-2026 The MathWorks, Inc.

PS4='+ [\d \t] '
set -x

# Set Node Type to make it available across reboots.
echo -e "export NODE_TYPE="${NODE_TYPE}"" | sudo tee -a /etc/profile.d/node-type.sh

# Applying correct permissions on home directory.
chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

# Enable run-userdata service
systemctl enable run-userdata.service

# Initialize cluster management data file.
termination_policy="${TERMINATION_POLICY}"

# Set auto_termination_flag as true if user's choice is anything other than 'Disable auto-termination'
auto_termination_flag=$([[ "${TERMINATION_POLICY}" != 'Disable auto-termination' ]] && echo "true" || echo "false")

# This boolean flag tells the clustermanagement program to use private IPs of the workers instead of hostnames
use_private_ip_mapping=$([[ -z "${CUSTOM_DNS_SUFFIX}" && "${ENABLE_PUBLIC_IP}" == "No" ]] && echo "true" || echo "false")

# Override termination policy to 'never' if auto-termination is disabled
if [[ "${TERMINATION_POLICY}" == 'Disable auto-termination' ]]; then
    termination_policy='never'
fi

# Modify the cluster management data file with the appropriate settings.
jq --arg desired_cap "${DESIRED_CAPACITY}" \
   --arg policy "$termination_policy" \
   --arg mjs_status_log_file "${MJS_STATUS_LOG_FILE}" \
   --argjson auto_termination_flag $auto_termination_flag \
   --arg custom_dns_suffix "${CUSTOM_DNS_SUFFIX}" \
   --argjson use_private_ip_mapping $use_private_ip_mapping \
   '.config.initial_desired_capacity=$desired_cap |
    .state.last_termination_policy=$policy |
    .config.initial_termination_policy=$policy |
    .config.mjs_status_log_file=$mjs_status_log_file |
    .config.autotermination_enabled=$auto_termination_flag |
    .config.custom_dns_suffix=$custom_dns_suffix |
    .config.use_private_ip_mapping=$use_private_ip_mapping' \
    ${CLUSTER_MANAGEMENT_DATA_FILE} > tmp.$$.json && mv tmp.$$.json ${CLUSTER_MANAGEMENT_DATA_FILE}

# Enable custom shutdown service on headnode
if [[ "${NODE_TYPE}" == "HEADNODE" ]]; then
    systemctl enable run-at-shutdown.service
    systemctl start run-at-shutdown.service
fi
