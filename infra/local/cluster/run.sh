#!/bin/bash

# This script is used to run a local cluster for testing purposes.
# It sets up a local Kubernetes cluster using KinD (Kubernetes in Docker) and configures the namespaces, fluxcd
# and other necessary components for the cluster to function properly.

LOCAL_BIN="$HOME/.local/bin"
CLUSTER_NAME="${1:-sigdep-cluster}"
KIND_CLUSTER_CONFIG="cluster-config.yml"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if ~/.local/bin exists, if not create it
if [ ! -d "$LOCAL_BIN" ]; then
    mkdir -p -m 750 "$LOCAL_BIN"
    echo "Created directory $LOCAL_BIN"
else
    echo "Directory $LOCAL_BIN already exists"
fi

# Add ~/.local/bin to the PATH if not already included
if ! echo "$PATH" | grep -q "$LOCAL_BIN"; then
  echo "Adding $LOCAL_BIN to PATH..."
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
else
    echo "$LOCAL_BIN is already in PATH"
fi

# Check if KinD, kubectl, flux and helm are installed
# Kind
if ! command_exists kind; then
    echo "KinD is not installed. Please install KinD to use this script."
    curl -Lo $LOCAL_BIN/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
    chmod 750 "$LOCAL_BIN/kind"
else
    echo "KinD is already installed"
    echo "KinD version: $(kind version)"
fi
# kubectl
if ! command_exists kubectl; then
    echo "kubectl is not installed. Please install kubectl to use this script."
    curl -Lo $LOCAL_BIN/kubectl https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
    chmod 750 "$LOCAL_BIN/kubectl"
else
    echo "kubectl is already installed"
    echo "kubectl version: $(kubectl version --client)"
fi
# flux
if ! command_exists flux; then
    echo "flux is not installed. Please install flux to use this script."
    curl -s https://fluxcd.io/install.sh | bash -s -- "$LOCAL_BIN"
    chmod 750 "$LOCAL_BIN/flux"
else
    echo "flux is already installed"
    echo "flux version: $(flux --version)"
fi
# helm
if ! command_exists helm; then
    echo "helm is not installed. Installing helm..."
    export HELM_INSTALL_DIR="$LOCAL_BIN"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -s -- --version v3.17.0 --no-sudo
    chmod 750 "$LOCAL_BIN/helm"
else
    echo "helm is already installed"
    echo "helm version: $(helm version)"
fi
# cloud-provider-kind
if ! command_exists cloud-provider-kind; then
    echo "Installing Kind Cloud Provider for External Load Balancer..."
    curl -L -o "$LOCAL_BIN/cloud-provider-kind.tar.gz" https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.6.0/cloud-provider-kind_0.6.0_linux_amd64.tar.gz
    command tar -xzf $LOCAL_BIN/cloud-provider-kind.tar.gz -C $LOCAL_BIN
    command chmod 750 $LOCAL_BIN/cloud-provider-kind
    command rm $LOCAL_BIN/cloud-provider-kind.tar.gz
    command rm $LOCAL_BIN/LICENSE
    command rm $LOCAL_BIN/README.md
else
    echo "cloud-provider-kind is already installed"
fi

# Cluster creation
if [ -f "$KIND_CLUSTER_CONFIG" ]; then
  echo "Creating Kind cluster from $KIND_CLUSTER_CONFIG..."
  # remove old cluster if it exists
  kind delete cluster --name $CLUSTER_NAME
  # create new cluster
  kind create cluster --name $CLUSTER_NAME --config $KIND_CLUSTER_CONFIG
  # set kubectl context to the new cluster
  echo "Setting kubectl context to kind-$CLUSTER_NAME..."
  kubectl config use-context kind-$CLUSTER_NAME
else
  echo "Kind config file not found. Aborting cluster creation."
  exit 1
fi

# Install calico for CNI
echo "Installing Calico CNI..."
helm repo add projectcalico https://docs.projectcalico.org/charts
helm repo update
kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --namespace tigera-operator --version v3.29.3

# Waiting for cluster to be ready
echo "Waiting for the cluster nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=1m

# Create namespaces
echo "Creating namespaces..."
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace storage
kubectl create namespace monitoring
kubectl create namespace logging

# Install k8s-dashboard
echo "Installing k8s-dashboard..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
helm install k8s-dashboard kubernetes-dashboard/kubernetes-dashboard \
    --namespace monitoring \
    --set protocolHttp=true
kubectl patch svc k8s-dashboard-kong-proxy -n monitoring \
  -p '{"spec": {"type": "LoadBalancer"}}'

kubectl wait --for=condition=available --timeout=1m deployment/k8s-dashboard -n monitoring
kubectl get svc -n monitoring -o wide

# Create a service account for the dashboard and cluster-admin role binding
echo "Creating service account for the dashboard..."
kubectl create serviceaccount dashboard-admin -n monitoring
kubectl create clusterrolebinding dashboard-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=monitoring:dashboard-admin

# Export the token used to access the dashboard
DASHBOARD_TOKEN=$(kubectl -n monitoring create token dashboard-admin)
echo "Dashboard token: $DASHBOARD_TOKEN"
