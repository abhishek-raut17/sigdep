#!/usr/bin/env bash

################################################ [scripts/func.sh] #########################################################
# This script contains main functions that support cluster setup and management.
# It includes:
# - Functions to create a cluster using Kind add namespaces, service accounts and bind roles.
# - Functions to set up a local registry and configure the cluster with it.
# - Functions to tag and push images to the local registry.
# - Functions to push images from a list to the local registry.
# - Functions to initialize monitoring on cluster resources.
#
# ==========================================================================================================================
# Import scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# =========================================================================================================================-
#
## Cluster management functions

### Function to initialize monitoring on cluster resources
monitor_cluster() {
    local cluster_name="${1:-$CLUSTER_NAME}"
    local timeout="${2:-300}"
    local condition="${3:-Ready}"
    local resource="${4:-nodes}"
    local namespace_flag="${5:---all-namespaces}"

    log warn "Monitoring cluster: $cluster_name \n\
        for condition: $condition \n\
        on resource: $resource \n\
        in namespace: $namespace_flag \n\
        with timeout: $timeout seconds"
    
    is_cluster_running "$cluster_name" || \
        fail_on_error "Cluster $cluster_name is not running."

    kubectl wait --for=condition="$condition" "$resource" --all $namespace_flag \
    --timeout="${timeout}s" || \
        fail_on_error "Failed to monitor cluster: $cluster_name"
}

### Function to check if cluster is running
is_cluster_running() {
    local cluster_name="${1:-$CLUSTER_NAME}"
    if kind get nodes --name $cluster_name | grep -q "$cluster_name"; then
        log info "Cluster $cluster_name is running."
        return 0
    else
        log warn "Cluster $cluster_name is not running."
        return 1
    fi
}

### Function to create a cluster using Kind
create_cluster() {
    log info "Creating Kind cluster: $CLUSTER_NAME"

    kind create cluster --name "$CLUSTER_NAME" \
        --config "$CLUSTER_CONFIG" || \
        fail_on_error "Failed to create Kind cluster."

    log verbose "Configuring kubectl to use the new cluster context..."
    kubectl config use-context kind-"$CLUSTER_NAME"
    log info "Kind cluster created successfully."
}

### Function to create k8s namespace
create_namespace() {
    local namespace="$1"

    if [ -z "$namespace" ]; then
        log error "Namespace name is required."
        return 1
    fi

    if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
        log verbose "Creating namespace: $namespace"
        kubectl create namespace "$namespace"
    else
        log verbose "Namespace $namespace already exists."
    fi
}

### Function to create a service account and bind it to a role
create_service_account() {
    local sa_name="$1"
    local role_type="$2"
    local role_binding="$3"
    local namespace="$4"

    if ! kubectl get serviceaccount "$sa_name" -n "$namespace" >/dev/null 2>&1; then
        log info "Creating service account: $sa_name in namespace: $namespace"
        kubectl create serviceaccount "$sa_name" -n "$namespace"
        kubectl create "$role_type"binding "$sa_name" \
            --"$role_type"="$role_binding" \
            --serviceaccount="$namespace:$sa_name"
        create_token_from_SA "$sa_name" "$namespace"
    else
        log verbose "Service account $sa_name already exists in namespace $namespace."
    fi
}

### Function to create token from serviceaccount
create_token_from_SA() {
    local sa_name="$1"
    local namespace="$2"

    log info "Creating token for ServiceAccount: $sa_name"
    kubectl create token "$sa_name" -n "$namespace" > token
    log verbose "Checkout token file at root folder location with the token to access k8s dashboard" 
}

# =========================================================================================================================-
## Dependency management functions

### Function to create a local registr
setup_registry() {
    log info "Setting up local registry..."

    # Create a local registry
    if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" != 'true' ]; then
        log verbose "Creating registry: $REGISTRY_NAME"

        docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" registry:2
        log info "Registry created: $REGISTRY_NAME"
    else
        log verbose "Registry already exists: $REGISTRY_NAME"
    fi

    log info "Local registry setup completed."
}

### Function to tag and push images to the local registry
push_to_local_registry() {
    local image_name="$1"
    local image_tag="$2"
    local registry_name=""

    # Check if the image is already present in the local registry
    if curl -s "http://localhost:${REGISTRY_PORT}/v2/$image_name/manifests/$image_tag" \
        | grep -q "errors"; then
        log verbose "Image not found in local registry: $image_name:$image_tag"

        # Check if the image is already present locally
        if docker images | grep -q "${image_name}" | grep -q "${image_tag}"; then
            log warn "Image already exists locally on host: $image_name:$image_tag"
        else
            log verbose "Pulling image from registry: $image_name:$image_tag"
            docker pull "$image_name:$image_tag" || \
                fail_on_error "Failed to pull image: $image_name:$image_tag"
        fi

        log verbose "Tagging image: $image_name:$image_tag"
        
        docker tag "$image_name:$image_tag" \
        "localhost:${REGISTRY_PORT}/$image_name:$image_tag" || \
            fail_on_error "Failed to tag image: $image_name:$image_tag"

        log info "Pushing image to local registry: \
        localhost:${REGISTRY_PORT}/$image_name:$image_tag"
        
        docker push "localhost:${REGISTRY_PORT}/$image_name:$image_tag" || \
            fail_on_error "Failed to push image: $image_name:$image_tag"
    else
        log verbose "Image already exists in local registry: $image_name:$image_tag"
    fi
}

### Function to push images from list to local registry
image_list_to_local_registry() {
    local image_list=("$@")
    for image in "${image_list[@]}"; do
        local image_name="${image%%:*}"
        local image_tag="${image##*:}"
        push_to_local_registry "$image_name" "$image_tag"
    done
    log info "$REGISTRY_NAME updated."
}

### Function to configure cluster with local registry
configure_cluster_registry() {
    log info "Configuring $CLUSTER_NAME with $REGISTRY_NAME..."

    # Check if the registry is already connected to the cluster network
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
        docker network connect "kind" "${REGISTRY_NAME}" || \
            fail_on_error "Failed to connect $REGISTRY_NAME to $CLUSTER_NAME network."
    fi

    # Create the directory for the registry configuration
    for node in $(kind get nodes --name $CLUSTER_NAME); do
        repoint_node_registry "$node"
    done

    # Document the local registry
    create_registry_configmap

    # Create headless Service and Endpoint for registry
    IPV4=$(docker network inspect kind -f \
    '{{ range $k, $v := .Containers }}{{ if eq $v.Name "sigdep-registry" }}{{ $v.IPv4Address }}{{ end }}{{ end }}' | \
    cut -d'/' -f1 | xargs)

    if [ -z "$IPV4" ]; then
        log error "Failed to retrieve IPv4 address for sigdep-registry. Ensure the registry is connected to the 'kind' network."
        return 1
    fi

    create_service_and_endpoint "$IPV4"
}

repoint_node_registry() {
    local node="$1"

    if [ -n "$node" ]; then
        
        log verbose "Repointing $node to ${REGISTRY_NAME}:${REGISTRY_PORT} .... "
        docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
        cat <<EOF | docker exec -i "${node}" tee "${REGISTRY_DIR}/hosts.toml"
server = "http://${REGISTRY_NAME}:${REGISTRY_PORT}"
[host."http://${REGISTRY_NAME}:${REGISTRY_PORT}"]
capabilities = ["pull", "push"]
insecure_skip_verify = true
EOF
    fi
}

create_registry_configmap() {

    log verbose "Setting configmap for ${REGISTRY_NAME} .... "
    cat <<EOF | kubectl apply -f - 
    apiVersion: v1
    kind: ConfigMap
    metadata:
        name: ${REGISTRY_NAME}-hosting
        namespace: kube-public
    data:
        localRegistryHosting.v1: |
            host: "localhost:${REGISTRY_PORT}"
            help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
}

create_service_and_endpoint() {
    local ip="$1"

    if [ -z "$ip" ]; then
        log error "Registry is not connect to kind network. Please reconnect to kind network"
        exit 1
    fi

    log verbose "Setting Service and Endpoint in kube-public namespace for ${REGISTRY_NAME} .... "
    cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Service
metadata:
  name: "${REGISTRY_NAME}"
  namespace: kube-public
spec:
  clusterIP: None
  ports:
    - name: registry
      port: ${REGISTRY_PORT}
      protocol: TCP
---
apiVersion: v1
kind: Endpoints
metadata:
  name: "${REGISTRY_NAME}"
  namespace: kube-public
subsets:
  - addresses:
      - ip: "${ip}"
    ports:
      - port: ${REGISTRY_PORT}
        protocol: TCP
EOF
}

# =========================================================================================================================-
## General utility management fuctions

### Generate ssh key pair
generate_ssh_key() {
    local message="$1"

  if [[ -f "${SSH_KEY_PATH}" && -f "${SSH_KEY_PATH}.pub" ]]; then
    log info "SSH keypair already exists at ${SSH_KEY_PATH}{,.pub}";
  else
    log verbose "Generating SSH keypair..."
    ssh-keygen -t rsa -C "$message" -f "${SSH_KEY_PATH}" -N ""
    log info "SSH keypair generated. Add ${SSH_KEY_PATH}.pub as deploy key to your Git repo."
  fi
}

### Create SSH secret
create_ssh_secret() {
    local secret_name="$1"
    local namespace="$2"

  log info "Creating SSH auth secret..."
  if [[ -s "${SSH_KEY_PATH}" && -s "${SSH_KEY_PATH}.pub" ]]; then
    
    flux create secret git flux-author-ssh \
        --namespace=$namespace \
        --url=ssh://$REPO_URL \
        --private-key-file=$SSH_KEY_PATH \
        --export \
    | kubectl apply -f -

  else
    log error "SSH keypair is missing or empty. Please generate a valid SSH keypair at ${SSH_KEY_PATH}{,.pub}."
    return 1
  fi
}

### Flux installation: apply git source
apply_git_source() {
    log info "Applying GitRepository source for FluxCD ..."
  
    cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: sigdep
  namespace: ${FLUX_NAMESPACE}
spec:
  interval: 1m
  url: ssh://$REPO_URL
  ref:
    branch: ${REPO_BRANCH}
  secretRef:
    name: ${FLUX_AUTHOR}-ssh
EOF

    log verbose "GitRepository source applied to FluxCD"
}

### Flux kustomization per component
apply_component_kustomization() {
    local component="${1:-}"

    if [ "$component" != "" ]; then
        log info "Applying kustomization for ${component}"
        kubectl apply -f "${component}"
        log verbose "Kustomizations for ${component} applied"
    fi
}

### Applies kustomizations to multiple components/services
apply_all_kustomizations() {
    local dir_list="${1:-${COMPONENT_DIRS}}"

    log info "Applying kustomization from ${dir_list}"
    if [ "$dir_list" != "" ]; then
        for d in ${dir_list}; do
            if [[ -f "${d}/deployment/kustomization.base.yaml" ]]; then
                apply_component_kustomization "${d}/deployment/kustomization.base.yaml"
            else
                log warn "Skipping ${d}: kustomization.base.yaml not found."
            fi
        done
    fi
}

################################################ [EOF] #####################################################################