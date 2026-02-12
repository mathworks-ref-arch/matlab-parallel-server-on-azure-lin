#!/usr/bin/env bash

# Copyright 2024-2026 The MathWorks, Inc.

COMPUTE_METADATA=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01")
SUBSCRIPTION_ID=$(echo "$COMPUTE_METADATA" | jq -r '.subscriptionId')
RESOURCE_ID=$(echo "$COMPUTE_METADATA" | jq -r '.resourceId')

az login --identity
az account set --subscription "${SUBSCRIPTION_ID}"
az tag update --resource-id "${RESOURCE_ID}" --operation Merge --tags mw-state=down || true
az logout
