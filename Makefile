#############################################################################################################
#
############# Makefile: SigDep #############
#
#############################################################################################################
#### Info:
#
# - Make file setups and configures a kind based k8s cluster for local dev and testing
# - Creates local registry on host machine to push/pull images for the cluster (microservices and infra)
# - Resolves all dependencies required for cluster (i.e. CNI plugin, k8s dashboard management)
# - Setup CI-CD pipeline with GitHub Webhooks + SMEE + Tekton
# - Predominanently uses bash for scripting automation
#
#############################################################################################################
#
## Setup Shell flags, color coding for stdout and scripts reference
#
SHELL := /usr/bin/env bash
MAKEFLAGS += --warn-undefined-variables
RESOURCE_DIR ?= scripts/local
SCRIPTS_DIR ?= $(RESOURCE_DIR)/make

HIGHLIGHT ?= \033[35m
NC ?= \033[0m
#
## Read variables from .env (if available or fallback to defaults)
#
ifneq (,$(wildcard .env))
	include .env
	export $(shell sed 's/=.*//' .env)
endif
#
#############################################################################################################
#
## Default variables
CLUSTER_NAME			?= sigdep
CLUSTER_CONFIG			?= $(RESOURCE_DIR)/cluster-config.yml
#
LOCAL_BIN         		?= $(HOME)/.local/bin
HELM_INSTALL_DIR 		?= $(LOCAL_BIN)
#
REGISTRY_NAME	 		?= sigdep-registry
REGISTRY_PORT	 		?= 5000
#
CLOUD_PROVIDER_KIND_URL ?= https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v0.6.0/cloud-provider-kind_0.6.0_linux_amd64.tar.gz
KIND_URL          		?= https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
KUBECTL_URL       		?= https://dl.k8s.io/release/$(shell curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
HELM_URL          		?= https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
#
HELM_CHART_CALICO       ?= https://docs.projectcalico.org/charts
HELM_CHART_DASHBOARD    ?= https://kubernetes-sigs.github.io/headlamp/
#
## Export variables for references
#
export CLUSTER_NAME CLUSTER_CONFIG LOCAL_BIN HELM_INSTALL_DIR
export REGISTRY_NAME REGISTRY_PORT
export CLOUD_PROVIDER_KIND_URL KIND_URL KUBECTL_URL HELM_URL
export HELM_CHART_CALICO HELM_CHART_DASHBOARD
#
#############################################################################################################
#
## PHONY
#
.PHONY: help defaults cleanup all pre-check binaries registry cluster cluster-setup cluster-dep cleanup-cluster cleamup-registry
#
#############################################################################################################
#
## Default Targets
#
help: ## Show available targets
	@echo -e "Usage: make <target>"
	@echo -e ""
	@grep -h -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"} ; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
#
defaults: ## Current config variables setup
	@echo -e "Default values:"
	@echo -e "  CLUSTER_NAME:               $(CLUSTER_NAME)"
	@echo -e "  RESOURCE_DIR:               $(RESOURCE_DIR)"
	@echo -e "  SCRIPTS_DIR:                $(SCRIPTS_DIR)"
	@echo -e "  CLUSTER_CONFIG:             $(CLUSTER_CONFIG)"
	@echo -e "  LOCAL_BIN:                  $(LOCAL_BIN)"
	@echo -e "  HELM_INSTALL_DIR:           $(HELM_INSTALL_DIR)"
	@echo -e "  REGISTRY_NAME:              $(REGISTRY_NAME)"
	@echo -e "  REGISTRY_PORT:              $(REGISTRY_PORT)"
	@echo -e "  KIND_URL:                   $(KIND_URL)"
	@echo -e "  KUBECTL_URL:                $(KUBECTL_URL)"
	@echo -e "  CLOUD_PROVIDER_KIND_URL:    $(CLOUD_PROVIDER_KIND_URL)"
	@echo -e "  HELM_URL:                   $(HELM_URL)"
	@echo -e "  HELM_CHART_CALICO:          $(HELM_CHART_CALICO)"
	@echo -e "  HELM_CHART_DASHBOARD:       $(HELM_CHART_DASHBOARD)"
#
#############################################################################################################
#
## Custom Targets
#
all: pre-check binaries registry cluster ## Complete setup of cluster with defaults
#
pre-check: ## Check pre-requisities for the setup
	@echo -e " ## ----------------------- Initializing target:  pre-check ----------------------- ## "
	@source $(SCRIPTS_DIR)/pre-check.sh
	@echo -e " ## ----------------------- Completed target:     pre-check ----------------------- ## "
#
binaries: ## Setup required binaries for cluster config and management
	@echo -e " ## ----------------------- Initializing target:  binaries  ----------------------- ## "
	@source $(SCRIPTS_DIR)/binaries.sh
	@echo -e " ## ----------------------- Completed target:     binaries  ----------------------- ## "
#
registry: ## Setup local registry
	@echo -e " ## ----------------------- Initializing target:  registry  ----------------------- ## "
	@source $(SCRIPTS_DIR)/registry.sh
	@echo -e " ## ----------------------- Completed target:     registry  ----------------------- ## "
#
cluster: cluster-setup cluster-dep ## Setup kind cluster based on default varialbes
#
cluster-setup: ## Setup cluster with configurations for local cluster-setup
	@echo -e " ## ----------------------- Initializing target:  cluster-setup  ------------------ ## "
	@source $(SCRIPTS_DIR)/cluster-setup.sh
	@echo -e " ## ----------------------- Completed target:     cluster-setup  ------------------ ## "
#
cluster-dep: ## Setup dependencies for the cluster including CNI
	@echo -e " ## ----------------------- Initializing target:  cluster-dep  -------------------- ## "
	@source $(SCRIPTS_DIR)/cluster-dep.sh
	@echo -e " ## ----------------------- Completed target:     cluster-dep  -------------------- ## "
#
cleanup: cleanup-cluster cleanup-registry ## Complete cleanup of cluster and its dependencies (registry, images, tags)
#
cleanup-cluster: ## Cleanup cluster and delete any ephermal entities
	@echo -e " ## ----------------------- Initializing target:  cleanup-cluster  -------------------- ## "
	@source $(SCRIPTS_DIR)/cleanup-cluster.sh
	@echo -e " ## ----------------------- Completed target:     cleanup-cluster  -------------------- ## "
#
cleanup-registry: ## Shutdown and cleanup local registry container
	@echo -e " ## ----------------------- Initializing target:  cleanup-registry  -------------------- ## "
	@source $(SCRIPTS_DIR)/cleanup-registry.sh
	@echo -e " ## ----------------------- Completed target:     cleanup-registry  -------------------- ## "
#
#############################################################################################################