.PHONY: help install validate deploy status logs exec metrics rpc ws grafana prometheus healthcheck test restart scale describe events top backup clean clean-all info update-config tf-init tf-plan tf-apply tf-destroy dev-setup quick-test cluster-create cluster-delete

# Configuration
CLUSTER_NAME ?= web3-node
NAMESPACE ?= web3
NETWORK ?= sepolia
CONTEXT ?= kind-$(CLUSTER_NAME)
REPLICAS ?= 1

# Resource Configuration (customizable)
STORAGE_SIZE ?= 100Gi
CPU_REQUEST ?= 500m
CPU_LIMIT ?= 2000m
MEMORY_REQUEST ?= 2Gi
MEMORY_LIMIT ?= 4Gi
CACHE_SIZE ?= 2048
MAX_PEERS ?= 50

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Web3 Node Platform - Makefile Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Install required dependencies
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)kubectl not found$(NC)"; exit 1; }
	@command -v kind >/dev/null 2>&1 || { echo "$(YELLOW)kind not found (optional)$(NC)"; }
	@command -v helm >/dev/null 2>&1 || { echo "$(YELLOW)helm not found (optional)$(NC)"; }
	@command -v terraform >/dev/null 2>&1 || { echo "$(YELLOW)terraform not found (optional)$(NC)"; }
	@echo "$(GREEN)All required dependencies installed$(NC)"

cluster-create: ## Create local kind cluster
	@echo "$(BLUE)Creating kind cluster: $(CLUSTER_NAME)$(NC)"
	@kind create cluster --name $(CLUSTER_NAME) --config docs/kind-config.yaml
	@kubectl cluster-info --context $(CONTEXT)
	@echo "$(GREEN)Cluster created successfully$(NC)"

cluster-delete: ## Delete local kind cluster
	@echo "$(YELLOW)Deleting kind cluster: $(CLUSTER_NAME)$(NC)"
	@kind delete cluster --name $(CLUSTER_NAME)
	@echo "$(GREEN)Cluster deleted$(NC)"

validate: ## Validate Kubernetes manifests and configurations
	@echo "$(BLUE)Validating configurations...$(NC)"
	@./scripts/validate-config.sh

deploy: ## Deploy full stack to Kubernetes
	@echo "$(BLUE)Deploying Web3 Node Platform...$(NC)"
	@./scripts/deploy.sh

status: ## Check deployment status
	@echo "$(BLUE)Checking deployment status...$(NC)"
	@./scripts/test.sh

logs: ## View Geth logs
	@kubectl logs -n $(NAMESPACE) statefulset/geth -f

exec: ## Shell into Geth container
	@kubectl exec -it -n $(NAMESPACE) geth-0 -- sh

metrics: ## Port-forward Prometheus metrics endpoint
	@echo "$(BLUE)Metrics available at http://localhost:6060/debug/metrics/prometheus$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/geth 6060:6060

rpc: ## Port-forward RPC endpoint
	@echo "$(BLUE)RPC available at http://localhost:8545$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/geth 8545:8545

ws: ## Port-forward WebSocket endpoint
	@echo "$(BLUE)WebSocket available at ws://localhost:8546$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/geth 8546:8546

grafana: ## Port-forward Grafana
	@echo "$(BLUE)Grafana available at http://localhost:3000 (admin/admin)$(NC)"
	@kubectl port-forward -n observability svc/grafana 3000:3000

prometheus: ## Port-forward Prometheus
	@echo "$(BLUE)Prometheus available at http://localhost:9090$(NC)"
	@kubectl port-forward -n observability svc/prometheus 9090:9090

rpc-test: ## Run RPC endpoint tests
	@./scripts/rpc-test.sh

test: ## Run comprehensive test suite
	@echo "$(BLUE)Running tests...$(NC)"
	@./scripts/test.sh

clean: ## Delete all resources
	@echo "$(YELLOW)Cleaning up resources...$(NC)"
	@kubectl delete namespace $(NAMESPACE) $(NAMESPACE)-monitoring || true
	@echo "$(GREEN)Cleanup complete$(NC)"

quick-test: cluster-create deploy ## Create cluster and deploy (Quick Start)
	@echo "$(GREEN)Quick Start complete! Waiting for pods...$(NC)"
	@kubectl wait --for=condition=ready pod -l app=geth -n $(NAMESPACE) --timeout=300s
