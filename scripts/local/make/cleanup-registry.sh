#!/usr/bin/env bash

################################################ [scripts/cleanup-registry.sh] #####################################################
# This script cleans up (shutdown) local registry
# It includes:
# - Shutdown local registry
#
# ==========================================================================================================================
#
## Import scripts/lib.sh and scripts/func.sh
#
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/func.sh"
#
# ==========================================================================================================================
#
## Cleanup after cluster is stopped
#
if docker ps --filter "name=${REGISTRY_NAME}" --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
    
    log warn "Standing down local registry: ${REGISTRY_NAME} ...."
    docker stop "${REGISTRY_NAME}" || \
        fail_on_error "Failed to stop local registry: ${REGISTRY_NAME}"
    docker container rm -f "${REGISTRY_NAME}"
    docker network rm -f "${REGISTRY_NAME}"
    
    log info "Local registry shutdown completed."

fi

log verbose " -------- Cleanup-Registry Activities Completed -------- "
#
################################################ [EOF] #####################################################################