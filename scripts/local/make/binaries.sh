#!/usr/bin/env bash

################################################ [scripts/binaries.sh] #####################################################
# This script installs required binaries for the kubernetes cluster setup and management.
# It includes:
# - Kind: Kubernetes in Docker
# - Kubectl: Kubernetes command-line tool
# - Helm: Kubernetes package manager
# - FluxCD: GitOps tool for Kubernetes
# - Cloud Provider Kind: A cloud provider for kind clusters
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
## Check if required binaries are installed
#
# Kind
install_binary "kind" "$KIND_URL"
validate_version kind
#
# kubectl
install_binary "kubectl" "$KUBECTL_URL"
validate_version kubectl "--client"
#
# Helm
export HELM_INSTALL_DIR="$LOCAL_BIN"
install_binary "helm" "$HELM_URL" "-fsS" "bash -s -- --version v3.17.0 --no-sudo"
validate_version helm
#
# FluxCD
install_binary "flux" "https://fluxcd.io/install.sh" "-s" "bash -s -- $LOCAL_BIN"
validate_version flux "--client"
#
#cloud-provider-kind
install_binary "cloud-provider-kind.tar.gz" "$CLOUD_PROVIDER_KIND_URL"
if ! command_exists cloud-provider-kind; then
    
    log verbose "Installing cloud-provider-kind"
    tar -xzf $LOCAL_BIN/cloud-provider-kind.tar.gz -C "$LOCAL_BIN" --strip-components=0 cloud-provider-kind
    rm -f $LOCAL_BIN/cloud-provider-kind.tar.gz
    chmod 750 $LOCAL_BIN/cloud-provider-kind
fi
#
################################################ [EOF] #####################################################################