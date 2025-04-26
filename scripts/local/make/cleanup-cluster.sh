#!/usr/bin/env bash

################################################ [scripts/cleanup-cluster.sh] #####################################################
# This script cleans up (shutdown) local cluster
# It includes:
# - Shutdown cluster
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
## Cleanup cluster, if active
#
if is_cluster_running "$CLUSTER_NAME"; then
    
    log warn "Cluster status: Running. Shutting it down .... "
    kind delete cluster --name "${CLUSTER_NAME}" || \
                fail_on_error "Failed to stop cluster: ${CLUSTER_NAME}"

    log info "Cluster shutdown completed."

    log verbose " -------- Cleanup-Cluster Activities Completed -------- "
fi
#
################################################ [EOF] #####################################################################