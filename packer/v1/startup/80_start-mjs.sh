#!/usr/bin/env bash

# Copyright 2022-2026 The MathWorks, Inc.

PS4='+ [\d \t] '
set -x

echo "===Setting up Networking==="

# Ensure that all communication with the headnode occurs on the local network.
# The variables HEADNODE_LOCAL_IP and HEADNODE_HOSTNAME are defined during deployment and set using the ARM template.
# HEADNODE_LOCAL_IP represents the private IPv4 address of the headnode.
# HEADNODE_HOSTNAME is the public FQDN if public IP is enabled, else, the local hostname of the headnode machine.
if [[ ${NODE_TYPE} == 'HEADNODE' ]]; then
    echo "${PRIVATE_IPV4} ${HEADNODE_HOSTNAME}" >> /etc/hosts
else
    echo "${HEADNODE_LOCAL_IP} ${HEADNODE_HOSTNAME}" >> /etc/hosts
fi

if [[ "${NODE_TYPE}" == 'HEADNODE' ]]; then
    # Hostname of the job manager.
    MJS_HOSTNAME="${HEADNODE_HOSTNAME}"
    EXTERNAL_HOSTNAME="${HEADNODE_HOSTNAME}"
    INTERNAL_HOSTNAME="${HEADNODE_INTERNAL_HOSTNAME}"
else
    # Hostname of the worker node
    MJS_HOSTNAME="${WORKER_INTERNAL_HOSTNAME}"
    EXTERNAL_HOSTNAME="${WORKER_EXTERNAL_HOSTNAME}"
    INTERNAL_HOSTNAME="${WORKER_INTERNAL_HOSTNAME}"
fi

# Ensure that the MATLAB client can connect directly to the workers. 
# This is a necessary condition to create parpools
export MDCE_OVERRIDE_EXTERNAL_HOSTNAME="${EXTERNAL_HOSTNAME}"
export MDCE_OVERRIDE_INTERNAL_HOSTNAME="${INTERNAL_HOSTNAME}"
export MPICH_INTERFACE_HOSTNAME="${INTERNAL_HOSTNAME}"

echo "===Starting MATLAB Job Scheduler==="

mkdir -p "${CHECKPOINT_ROOT}"
chmod 755 "${CHECKPOINT_ROOT}"

MJS_OPTS=(
    -hostname "${MJS_HOSTNAME}"
    -loglevel ${CLUSTER_LOG_LEVEL%%-*}
    -enablepeerlookup
    -sharedsecretfile ${SECRET_FILE}
    -cleanPreserveJobs
    -sendactivitynotifications
    -scriptroot ${MJS_BUSY_IDLE_SCRIPTS}
)

cd "${MATLAB_ROOT}/toolbox/parallel/bin" || exit 1
./mjs start "${MJS_OPTS[@]}"

if [[ "${NODE_TYPE}" == 'HEADNODE' ]]; then
    echo "===Starting Job Manager==="

    if [[ -f "${MJS_ADMIN_PASSWORD_FILE}" ]]; then
        # Provide the password for the administrator account if one has been generated (Security Level 2 and 3)
        MDCEQE_JOBMANAGER_ADMIN_PASSWORD=$(cat "${MJS_ADMIN_PASSWORD_FILE}")
        export MDCEQE_JOBMANAGER_ADMIN_PASSWORD
        
        PARALLEL_SERVER_JOBMANAGER_ADMIN_PASSWORD="${MDCEQE_JOBMANAGER_ADMIN_PASSWORD}"
        export PARALLEL_SERVER_JOBMANAGER_ADMIN_PASSWORD
    fi
    ./startjobmanager -name "${JOB_MANAGER_NAME}" -certificate "${CERT_FILE}"

    if [[ ${ENABLE_AUTOSCALING} == 'Yes' ]] || [[ ${TERMINATION_POLICY} != 'Disable auto-termination' ]]; then
        # Enable cluster management service.
        systemctl enable clustermanagement.timer
        systemctl start clustermanagement.timer
    fi

else

    echo "===Wait until Headnode is available and start workers==="
    PORT=22
    TIMEOUT=600
    RETRY_INTERVAL=10

    echo "Checking if SSH service is up and nodestatus is Running on ${HEADNODE_HOSTNAME}..."
    END_TIME=$((SECONDS+TIMEOUT))

    while [[ $SECONDS -lt $END_TIME ]]; do
        if nc -z -w5 "${HEADNODE_HOSTNAME}" "$PORT"; then
            echo "SSH service is up on ${HEADNODE_HOSTNAME}."
            
            STATUS=$(./nodestatus -remotehost "${HEADNODE_HOSTNAME}" -json | jq -r '.lookupProcess.status')
            if [[ "$STATUS" = "Running" ]]; then
                echo "nodestatus is responsive and Running on ${HEADNODE_HOSTNAME}."
                ./startworker -jobmanagerhost "${HEADNODE_HOSTNAME}" -jobmanager "${JOB_MANAGER_NAME}" -num "${WORKERS_PER_NODE}"
                echo "===Done==="
                exit 0
            else
                echo "nodestatus on ${HEADNODE_HOSTNAME} is not Running. Retrying in ${RETRY_INTERVAL} seconds..."
            fi
        else
            echo "SSH service is not responding on ${HEADNODE_HOSTNAME}. Retrying in ${RETRY_INTERVAL} seconds..."
        fi
        sleep $RETRY_INTERVAL
    done

    echo "Timeout reached. SSH service did not come up or nodestatus did not return Running on ${HEADNODE_HOSTNAME}"
    exit 1
fi
