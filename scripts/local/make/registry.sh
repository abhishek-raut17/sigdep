#!/usr/bin/env bash

################################################ [scripts/registry.sh] #########################################################
# This script sets up and stands a local registry for cluster and components images
# It includes:
# - Setup local registry
# - Pulling images from remote docker repository and tagging and pushing them to local registry
#
# ==========================================================================================================================
#
## Import scripts/lib.sh and scripts/func.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/func.sh"
#
# ==========================================================================================================================
#
## Setup local registry
setup_registry
#
# ==================================================================================================================================
#
## Import initialization critical images to local registry
#
# Import Calico images to local registry
log verbose "Importing Calico images to local registry..."
image_list_to_local_registry "${CALICO_IMAGES[@]}" || \
   fail_on_error "Failed to import Calico images to local registry."
#
# Import k8s-dashboard images to local registry
log verbose "Importing k8s-dashboard images to local registry..."
image_list_to_local_registry "${DASHBOARD_IMAGES[@]}" || \
   fail_on_error "Failed to import k8s-dashboard images to local registry."

log info "All images imported to local registry successfully."

################################################ [EOF] #####################################################################