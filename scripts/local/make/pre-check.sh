#!/usr/bin/env bash

################################################ [scripts/pre-check.sh] #########################################################
# This script does prerequsites check before setting up the cluster.
# It includes:
# - Check if required files are present (cluster config, cloud_provider_kind URL, kind URL, kubectl URL, helm URL)
# - Check if docker is installed and running
# - Check if $LOCAL_BIN is available and in PATH
# - Generates SSH key pair for FluxCD
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
## Log run details
#
log info "Cluster name set to: $CLUSTER_NAME"
log info "Using registry: $REGISTRY_NAME"
log verbose "Using cluster config: $CLUSTER_CONFIG"
log warn "Binaries installation directory set to: $LOCAL_BIN"
#
# ==========================================================================================================================
#
## Pre-requisites check
#
# Check required files are present
check_file "$CLUSTER_CONFIG"
check_file "$LOCAL_BIN"
check_file "$CLOUD_PROVIDER_KIND_URL"
check_file "$KIND_URL"
check_file "$KUBECTL_URL"
check_file "$HELM_URL"
#
# Check if $LOCAL_BIN is available and in PATH
check_local_bin
#
# Check if docker is installed and running
check_docker_status
#
################################################ [EOF] #####################################################################