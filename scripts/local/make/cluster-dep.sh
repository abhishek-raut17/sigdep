#!/usr/bin/env bash

################################################ [scripts/cluster-dep.sh] ##################################################
# This script sets up the dependencies for the cluster
# It includes:
# - Setting up KinD cluster
# - Attaching it to local registry to pull all images
#
# ==========================================================================================================================
#
## Import scripts/lib.sh and scripts/func.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/func.sh"
#
# ==========================================================================================================================
#
## Create namespaces in the cluster
#
create_namespace "prod"
create_namespace "devstack"
create_namespace "monitoring"
create_namespace "storage"
create_namespace "pipelines"
#
# ==========================================================================================================================
## Install Calico CNI
#
log info "Installing Calico CNI..."

validate_helm_repo "projectcalico" "${HELM_CHART_CALICO}"
if [[ $? -eq 0 ]]; then

    helm upgrade --install calico projectcalico/tigera-operator \
    --namespace tigera-operator \
    --create-namespace \
    --version "${CALICO_VERSION}" \
    --set installation.registry=localhost:5000/ \
    --set tigeraOperator.registry=localhost:5000/quay.io/ || \
    fail_on_error "Failed to install Calico CNI."
fi

monitor_cluster "$CLUSTER_NAME" 100 "Ready" "pods" "--namespace tigera-operator"
monitor_cluster "$CLUSTER_NAME" 100 "Ready" "nodes"
monitor_cluster "$CLUSTER_NAME" 250 "Ready" "pods" "--namespace calico-system"

log verbose "Calico CNI installed successfully."
#
# ==========================================================================================================================
#
## Install Headlamp for k8s dashboard
#
log info "Installing Headlamp UI for kubernetes dashboard..."

validate_helm_repo "headlamp" "${HELM_CHART_DASHBOARD}"
if [[ $? -eq 0 ]]; then

    helm upgrade --install "$DASHBOARD_NAME" headlamp/headlamp \
    --namespace monitoring \
    --set config.inCluster=true \
    --set service.type=LoadBalancer \
    --set ingress.enabled=true \
    --set ingress.hosts[0].host=headlamp.monitoring.$CLUSTER_NAME \
    --set ingress.hosts[0].paths[0].path=/ \
    --set ingress.hosts[0].paths[0].type=ImplementationSpecific || \
    fail_on_error "Failed to install Calico CNI."
fi

monitor_cluster "$CLUSTER_NAME" 100 "Ready" "pods" "--namespace monitoring"
monitor_cluster "$CLUSTER_NAME" 100 "Ready" "nodes"

create_token_from_SA "$DASHBOARD_NAME-headlamp" monitoring
log verbose "Headlanp UI for k8s dashboard installed successfully."
#
################################################ [EOF] #####################################################################