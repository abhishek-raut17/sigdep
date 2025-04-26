#!/usr/bin/env bash

################################################ [scripts/cluster-setup.sh] ################################################
# This script sets up the actual kind cluster
# It includes:
# - Setting up KinD cluster
# - Attaching it to local registry to pull all images
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
## Create Kind cluster
#
## Check if the Kind cluster is running, create it if not
is_cluster_running "$CLUSTER_NAME" || create_cluster || \
    fail_on_error "Failed to create Kind cluster."
#
## Configure the Kind cluster with the local registry
configure_cluster_registry || \
   fail_on_error "Failed to configure Kind cluster with local registry."
#
################################################ [EOF] #####################################################################