#!/usr/bin/env bash

################################################ [scripts/lib.sh] ##########################################################
# This script contains predefined variables and utility functions for the main script.
# It includes:
# - Variables for the script cluster info and name, image versions, binary asset URLs. (Exported from Makefile)
# - Functions to log different severity levels and error handling.
# - Functions to check if required commands are available and to validate binary installation.
# - Functions to install binaries via curl and to validate Helm charts.
# - Functions to check if Docker is installed and running.
#
# ==========================================================================================================================
#
## Default error handling
#
set -euo pipefail
trap 'echo "Error occurred in script at line $LINENO. Exiting..."; exit 1;' ERR
trap 'echo "Script interrupted. Cleaning up..."; cleanup' INT TERM
#
## Colors for logging
#
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color
#
# ==========================================================================================================================
#
## Variables and Command-line Arguments
#
## Default version variables
CALICO_VERSION="v3.29.3"
KIND_VERSION="v0.27.0"
CLOUD_PROVIDER_KIND_VERSION="0.6.0"
TIGERA_OPERATOR_VERSION="v1.36.7"
HEADLAMP_VERSION="v0.30.0"
#
## Default variables
: "${LOCAL_BIN:="$HOME/.local/bin"}"
: "${HELM_INSTALL_DIR:="$HOME/.local/bin"}"
: "${CLUSTER_CONFIG:="cluster-config.yml"}"
: "${CLUSTER_NAME:="sigdep-cluster"}"
: "${REGISTRY_NAME:="sigdep-registry"}"
: "${REGISTRY_PORT:=5000}"
#
## URLs for downloading binaries
: "${CLOUD_PROVIDER_KIND_URL:="https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v${CLOUD_PROVIDER_KIND_VERSION}/cloud-provider-kind_${CLOUD_PROVIDER_KIND_VERSION}_linux_amd64.tar.gz"}"
: "${HELM_URL:="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"}"
: "${KIND_URL:="https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"}"
: "${KUBECTL_URL:="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"}"
#
## Default HELM Charts
: "${HELM_CHART_CALICO:="https://docs.projectcalico.org/charts"}"
: "${HELM_CHART_DASHBOARD:="https://kubernetes-sigs.github.io/headlamp/"}"
#
## Derived variables
REGISTRY_DIR="/etc/containerd/certs.d/${REGISTRY_NAME}:${REGISTRY_PORT}"
DASHBOARD_NAME="${CLUSTER_NAME}-dashboard"
#
## Calico CNI images
CALICO_IMAGES=(
    quay.io/tigera/operator:${TIGERA_OPERATOR_VERSION}
    calico/apiserver:${CALICO_VERSION}
    calico/cni:${CALICO_VERSION}
    calico/csi:${CALICO_VERSION}
    calico/node-driver-registrar:${CALICO_VERSION}
    calico/pod2daemon-flexvol:${CALICO_VERSION}
    calico/kube-controllers:${CALICO_VERSION}
    calico/node:${CALICO_VERSION}
    calico/typha:${CALICO_VERSION}
)
#
## k8s-dashboard images
DASHBOARD_IMAGES=(
    ghcr.io/headlamp-k8s/headlamp:${HEADLAMP_VERSION}
)
#
# ==========================================================================================================================
## Logger (echo) function

### Function to log messages with different severity levels
log() {
    local type="$1"
    local message="$2"
    
    case $type in
        info)
            echo -e "${GREEN} + + + + + + [INFO]  ${message}  + + + + + + ${NC}"
            ;;
        error)
            echo -e "${RED} ! ! ! ! ! ! [ERROR] ${message} ! ! ! ! ! ! ${NC}"
            ;;
        warn)
            echo -e "${YELLOW} # # # # # # [WARN]  ${message} # # # # # # ${NC}"
            ;;
        verbose)
            echo -e "${BLUE} - - - - - - [DEBUG] ${message} - - - - - - ${NC}"
            ;;
        *)
            echo -e " [UKNOWN] ${message} "
            ;;
    esac
}

# ==========================================================================================================================
## Error handling

fail_on_error() {
    local message="$1"
    log error "${message}"
    exit 1
}

# ==========================================================================================================================
## Utility Functions

### Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

### Function to check if a file exists
check_file() {
    local file="$1"
    if [[ "$file" =~ ^https?:// ]]; then

        # Check if the URL is reachable
        if ! curl --head --silent --fail "$file" > /dev/null; then
            log error "URL not reachable: $file"
            exit 1
        fi
    elif [ ! -e "$file" ]; then
        log error "File or directory not found: $file"
        exit 1
    fi
}

### Function to check if $LOCAL_BIN dir is avaialbe and in PATH
check_local_bin() {

    # Check if $LOCAL_BIN exists and create it if not
    if [ ! -d "$LOCAL_BIN" ]; then
        mkdir -p -m 750 "$LOCAL_BIN"
        log info "Created directory: $LOCAL_BIN"
    else
        log verbose "$LOCAL_BIN already exists."
    fi

    # Add $LOCAL_BIN to the PATH if not already included
    if ! echo "$PATH" | grep -q "$LOCAL_BIN"; then
        log info "Adding $LOCAL_BIN to PATH"

        if [ -f ~/.bashrc ]; then
            echo -e 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            source ~/.bashrc
        fi

        echo -e 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    else
        log verbose "$LOCAL_BIN is already in PATH."
    fi
}

### Function to check if Docker is installed and running
check_docker_status() {

    if ! command_exists docker; then
        log error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! docker ps >/dev/null 2>&1; then
        log info "Docker is not running. Starting Docker..."
        systemctl start docker || fail_on_error "Failed to start Docker."
    fi

    log info "Docker is installed and running."
}

### Function to validate binary installation version
validate_version() {
    local bin_name="$1"
    local flag="${2:-}"

    if command_exists "$bin_name"; then
        log verbose "Validating version of $bin_name"
        
        if [ -n "$flag" ]; then
            eval $bin_name \ version \ "$flag"
        else
            eval $bin_name \ version
        fi
    else
        log error "$bin_name is not installed. Please install it first."
        exit 1
    fi
}

### Function to install binaries via curl
install_binary() {
    
    local bin_name_input=${1:-$(basename "$bin_url")}
    local bin_name=${bin_name_input%%.*}
    local bin_url="$2"
    local curl_flags="${3:--L}"
    local pipe_flags="${4:-}"
    local bin_location="${5:-$LOCAL_BIN}"
    local bin_path="$bin_location/$bin_name_input"

    if [ -z "$bin_url" ]; then
        log error "No installation URL provided for $bin_name. Exiting..."
        return 1
    fi

    log verbose "Checking for: $bin_name"    
    log verbose "Locating in : $bin_location"
    
    if ! command_exists "$bin_name"; then
        log verbose "Downloading $bin_name from $bin_url"
        log info "Installing $bin_name to $bin_path"

        if [ "$pipe_flags" != "" ]; then
            curl $curl_flags "$bin_url" | $pipe_flags
        else
            curl $curl_flags "$bin_url" -o "$bin_path"
        fi

        chmod 750 "$bin_path"
        log info "$bin_name installed successfully at $bin_path"
    else
        log info "$bin_name is already installed at $bin_path"
    fi

}

### Function to add and update Helm charts
validate_helm_repo() {
    local project_name="${1:-""}"
    local project_url="${2:-""}"

    if [ -z "$project_name" -o -z "$project_url" ]; then
        log error "Arguments missing. Skipping Helm repo validation."
        return 1
    fi

    if ! command_exists helm; then
        log error "Helm is not installed. Please install Helm first."
        return 1
    fi

    log verbose "Validating Helm repo for $project_name"

    if [ ! -f "$HOME/.cache/helm/repository/$project_name-index.yaml" ]; then
        helm repo add $project_name $project_url || \
            fail_on_error "Failed to add Helm repo: $project_name"
        helm repo update
    else 
        log verbose "Helm repo for $project_name already exists."
    fi
}

################################################ [EOF] #####################################################################