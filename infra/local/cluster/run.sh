#!/bin/bash

# This script is used to run a local cluster for testing purposes.
# It sets up a local Kubernetes cluster using KinD (Kubernetes in Docker) 
# and configures the namespaces, fluxcd and other necessary components for 
# the cluster to function properly.

# If run successfully, this script will output a token that 
# can be used to access the Kubernetes dashboard.


# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No color

set -e
trap 'echo "${RED}An error occurred. Exiting..."' ERR
trap 'echo "${RED}Script interrupted. Exiting..."' SIGINT SIGTERM

# Variables
LOCAL_BIN="$HOME/.local/bin"
CLUSTER_NAME="${1:-sigdep-cluster}"
KIND_CLUSTER_CONFIG="cluster-config.yml"

# Checks if the bin exists in the PATH
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a binary if it doesn't exist (defaults to ~/.local/bin)
install_binary() {
    
    local bin_name_input=${1:-$(basename "$bin_url")}
    local bin_name=${bin_name_input%%.*}
    local curl_flags="${2:--L}"
    local bin_url="$3"
    local pipe_flags="${4:-}"
    local bin_location="${5:-$LOCAL_BIN}"
    local bin_path="$bin_location/$bin_name"

    echo -e "${YELLOW}Checking for $bin_name...${NC}"
    echo -e "${BLUE}Locating in: $bin_location${NC}"
    
    if [ -z "$bin_url" ]; then
        echo -e "${RED}No URL provided for $bin_name. Skipping installation.${NC}"
        return 1
    fi
    
    if ! command_exists "$bin_name"; then
        echo -e "${YELLOW}Installing $bin_name...${NC}"
        echo -e "${BLUE}Downloading $bin_name...${NC}"

        if [ "$pipe_flags" != "" ]; then
            curl $curl_flags "$bin_url" | $pipe_flags
        else
            curl $curl_flags "$bin_url" -o "$bin_path"
        fi

        chmod 750 "$bin_path"
        echo -e "${GREEN}$bin_name installed successfully.${NC}"
    else
        echo -e "${GREEN}$bin_name is already installed.${NC}"
        echo -e "${BLUE}Path: $bin_path${NC}"
    fi
}

# Validate the version of a binary in path
validate_version() {
    local bin_name="$1"
    local version_flag="$2"

    if command_exists "$bin_name"; then
        echo -e "${YELLOW}Validating $bin_name version...${NC}"
        if [ -n "$version_flag" ]; then
            eval $bin_name \ version \ "$version_flag"
        else
            eval $bin_name \ version
        fi
    else
        echo -e "${RED}$bin_name is not installed.${NC}"
    fi
}

# Monitor Cluster resources
monitor_cluster() {
    local condition="${1:-Ready}"
    local timeout="${2:-2m}"
    local resource="${3:-nodes}"
    local namespace="${4:-all}"
    local all_flag="$5"

    echo -e "${RED}Waiting $timeout for $resource to be $condition in $namespace namespace...${NC}"

    if [ "$all_flag" == "--all" ]; then
        kubectl wait --for=condition="$condition" "$resource" \
            --all --timeout="$timeout"
    else
        kubectl wait --for=condition="$condition" "$resource" \
            --namespace "$namespace" --timeout="$timeout"
    fi
}

# Helm charts add and update repo
validate_helm_repo() {
    local project_name="${1}"

    echo -e "${YELLOW}Validating Helm repo for $project_name...${NC}"
    
    if ! command_exists helm; then
        echo -e "${RED}Helm is not installed. Skipping Helm repo validation.${NC}"
        return 1
    fi

    if [ -z "$project_name" ]; then
        echo -e "${RED}No project name provided. Skipping Helm repo validation.${NC}"
        return 1
    fi

    if [ ! -f "$HOME/.cache/helm/repository/$project_name-index.yaml" ]; then
        helm repo add $project_name https://docs.projectcalico.org/charts
        helm repo update
    else 
        echo -e "${BLUE}Helm repo $project_name already exists.${NC}"
    fi
}

# Create k8s namespace
create_namespace() {
    local namespace="$1"

    if [ -z "$namespace" ]; then
        echo -e "${RED}No namespace provided. Skipping namespace creation.${NC}"
        return 1
    fi

    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        echo -e "${YELLOW}Creating namespace $namespace...${NC}"
        kubectl create namespace "$namespace"
    else
        echo -e "${BLUE}Namespace $namespace already exists.${NC}"
    fi
}

# Check if ~/.local/bin exists, if not create it
if [ ! -d "$LOCAL_BIN" ]; then
    mkdir -p -m 750 "$LOCAL_BIN"
    echo -e "${GREEN}Created directory $LOCAL_BIN${NC}"
else
    echo -e "${BLUE}Directory $LOCAL_BIN already exists.${NC}"
fi

# Add ~/.local/bin to the PATH if not already included
if ! echo "$PATH" | grep -q "$LOCAL_BIN"; then
  echo -e "${YELLOW}Adding $LOCAL_BIN to PATH...${NC}"
  echo -e 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
else
    echo -e "${BLUE}$LOCAL_BIN is already in PATH.${NC}"
fi

# Check if KinD, kubectl, flux and helm are installed
# Kind
install_binary "kind" "-L" "https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64"
validate_version "kind"

# Kubectl
install_binary "kubectl" "-L" \
    "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
validate_version "kubectl" "--client"

# FluxCD
install_binary "flux" "-s" "https://fluxcd.io/install.sh" "bash -s -- $LOCAL_BIN"
validate_version "flux" "--client"

# Helm
export HELM_INSTALL_DIR="$LOCAL_BIN"
install_binary "helm" "-fsSL" \
    "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" \
    "bash -s -- --version v3.17.0 --no-sudo"
validate_version "helm"

# cloud-provider-kind
# This is a KinD-specific cloud provider that allows you to use an external load balancer with KinD.
install_binary "cloud-provider-kind.tar.gz" "-L" \
    "https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.6.0/cloud-provider-kind_0.6.0_linux_amd64.tar.gz"
if [[ -f "$LOCAL_BIN/cloud-provider-kind" && -f "$LOCAL_BIN/cloud-provider-kind.tar.gz" ]]; then
    command tar -xzf $LOCAL_BIN/cloud-provider-kind.tar.gz -C $LOCAL_BIN
    command rm $LOCAL_BIN/cloud-provider-kind.tar.gz
    command rm $LOCAL_BIN/LICENSE
    command rm $LOCAL_BIN/README.md
    command chmod 750 $LOCAL_BIN/cloud-provider-kind
    command cloud-provider-kind &
fi

# Cluster creation
if [ -f "$KIND_CLUSTER_CONFIG" ]; then
    echo -e "${BLUE}Creating Kind cluster from $KIND_CLUSTER_CONFIG...${NC}"

    if kind get clusters | grep -q "$CLUSTER_NAME"; then
        echo -e "${YELLOW}Cluster $CLUSTER_NAME already exists....${NC}"
    else 
        kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CLUSTER_CONFIG"
        echo -e "${GREEN}Cluster $CLUSTER_NAME created successfully.${NC}"

        # Set the context for kubectl to use the new cluster
        echo -e "${YELLOW}Configuring kubectl context...${NC}"
        kubectl config use-context kind-"$CLUSTER_NAME"
    fi
else
    echo "Kind config file not found. Aborting cluster creation."
    exit 1
fi

# Install Calico for CNI
echo -e "${YELLOW}Installing Calico CNI...${NC}"
validate_helm_repo "projectcalico"
helm upgrade --install calico projectcalico/tigera-operator \
    --namespace tigera-operator \
    --create-namespace

# Wait for Calico components to be ready
monitor_cluster "Available" "2m" "deployments.apps/tigera-operator" "tigera-operator"
monitor_cluster "Ready" "2m" "nodes" "" "--all"

# Create namespaces
create_namespace "frontend"
create_namespace "backend"
create_namespace "storage"
create_namespace "monitoring"
create_namespace "logging"

# Install k8s-dashboard
echo -e "Installing k8s-dashboard..."
validate_helm_repo "kubernetes-dashboard"
helm upgrade --install k8s-dashboard kubernetes-dashboard/kubernetes-dashboard \
    --namespace monitoring \
    --set protocolHttp=true

# Wait for k8s-dashboard components to be ready
monitor_cluster "Available" "2m" "deployments.apps/k8s-dashboard-kong" "monitoring"
kubectl patch svc k8s-dashboard-kong-proxy -n monitoring \
  -p '{"spec": {"type": "LoadBalancer"}}'

monitor_cluster "Ready" "2m" "services/k8s-dashboard-kong-proxy" "monitoring"
echo -e "${GREEN}k8s-dashboard installed successfully.${NC}"

# Create a service account for the dashboard and cluster-admin role binding
echo -e "Creating service account for the dashboard..."
kubectl create serviceaccount dashboard-admin -n monitoring
kubectl create clusterrolebinding dashboard-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=monitoring:dashboard-admin

# Export the token used to access the dashboard
DASHBOARD_TOKEN=$(kubectl -n monitoring create token dashboard-admin)
echo -e "Dashboard token: $DASHBOARD_TOKEN"
