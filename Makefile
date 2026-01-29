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

validate: ## Validate Kubernetes manifests
	@echo "$(BLUE)Validating manifests...$(NC)"
	@kubectl apply --dry-run=client -f kubernetes/base/ || exit 1
	@kubectl apply --dry-run=client -f kubernetes/ethereum/ || exit 1
	@kubectl apply --dry-run=client -f kubernetes/observability/ || exit 1
	@echo "$(GREEN)All manifests valid$(NC)"

lint: ## Lint Kubernetes manifests
	@echo "$(BLUE)Linting manifests...$(NC)"
	@if command -v kubeconform >/dev/null 2>&1; then \
		kubeconform -summary -output json kubernetes/; \
	else \
		echo "$(YELLOW)kubeconform not found, skipping$(NC)"; \
	fi

deploy: validate ## Deploy to Kubernetes
	@echo "$(BLUE)Deploying to $(NAMESPACE) namespace (Network: $(NETWORK))...$(NC)"
	@echo "$(BLUE)Resources: CPU=$(CPU_REQUEST)-$(CPU_LIMIT), Memory=$(MEMORY_REQUEST)-$(MEMORY_LIMIT), Storage=$(STORAGE_SIZE)$(NC)"
	@kubectl apply -f kubernetes/base/
	@kubectl create configmap geth-config \
		--from-literal=NETWORK=$(NETWORK) \
		--from-literal=SYNC_MODE=snap \
		--from-literal=HTTP_PORT=8545 \
		--from-literal=WS_PORT=8546 \
		--from-literal=METRICS_PORT=6060 \
		--from-literal=P2P_PORT=30303 \
		--from-literal=HTTP_API="eth,net,web3,txpool" \
		--from-literal=WS_API="eth,net,web3" \
		--from-literal=HTTP_CORS_ORIGINS="*" \
		--from-literal=HTTP_VHOSTS="*" \
		--from-literal=CACHE_SIZE=$(CACHE_SIZE) \
		--from-literal=MAX_PEERS=$(MAX_PEERS) \
		--from-literal=LOG_LEVEL=info \
		--namespace=$(NAMESPACE) \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl apply -f kubernetes/ethereum/
	@echo "$(GREEN)Deployment started. Use 'make status' to check progress$(NC)"

deploy-observability: ## Deploy observability stack
	@echo "$(BLUE)Deploying observability stack...$(NC)"
	@kubectl apply -f kubernetes/observability/
	@echo "$(GREEN)Observability stack deployed$(NC)"

status: ## Check deployment status
	@echo "$(BLUE)Deployment Status:$(NC)"
	@kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "$(BLUE)Persistent Volume Claims:$(NC)"
	@kubectl get pvc -n $(NAMESPACE)
	@echo ""
	@echo "$(BLUE)Pod Details:$(NC)"
	@kubectl get pods -n $(NAMESPACE) -o wide

logs: ## View node logs
	@echo "$(BLUE)Viewing logs (Ctrl+C to exit)...$(NC)"
	@kubectl logs -n $(NAMESPACE) -l app=geth --tail=100 -f

logs-previous: ## View previous pod logs
	@kubectl logs -n $(NAMESPACE) -l app=geth --tail=100 --previous

exec: ## Shell into node container
	@echo "$(BLUE)Connecting to geth-0...$(NC)"
	@kubectl exec -it -n $(NAMESPACE) geth-0 -- sh

exec-geth: ## Attach to Geth console
	@echo "$(BLUE)Attaching to Geth console...$(NC)"
	@kubectl exec -it -n $(NAMESPACE) geth-0 -- geth attach /data/geth.ipc

metrics: ## Port-forward metrics endpoint
	@echo "$(BLUE)Port-forwarding metrics on http://localhost:6060$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/geth 6060:6060

rpc: ## Port-forward RPC endpoint
	@echo "$(BLUE)Port-forwarding RPC on http://localhost:8545$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/geth 8545:8545

ws: ## Port-forward WebSocket endpoint
	@echo "$(BLUE)Port-forwarding WebSocket on ws://localhost:8546$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/geth 8546:8546

grafana: ## Port-forward Grafana
	@echo "$(BLUE)Port-forwarding Grafana on http://localhost:3000$(NC)"
	@kubectl port-forward -n observability svc/grafana 3000:3000

prometheus: ## Port-forward Prometheus
	@echo "$(BLUE)Port-forwarding Prometheus on http://localhost:9090$(NC)"
	@kubectl port-forward -n observability svc/prometheus 9090:9090

healthcheck: ## Run health check
	@echo "$(BLUE)Running health check...$(NC)"
	@bash scripts/healthcheck.sh

test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	@bash scripts/test.sh

restart: ## Restart the node
	@echo "$(YELLOW)Restarting geth StatefulSet...$(NC)"
	@kubectl rollout restart statefulset/geth -n $(NAMESPACE)
	@kubectl rollout status statefulset/geth -n $(NAMESPACE) --timeout=10m

scale: ## Scale replicas (use REPLICAS=n)
	@echo "$(BLUE)Scaling to $(REPLICAS) replicas...$(NC)"
	@kubectl scale statefulset/geth -n $(NAMESPACE) --replicas=$(REPLICAS)

describe: ## Describe node pod
	@kubectl describe pod -n $(NAMESPACE) -l app=geth

events: ## Show recent events
	@kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp'

top: ## Show resource usage
	@echo "$(BLUE)Node Resource Usage:$(NC)"
	@kubectl top pod -n $(NAMESPACE) -l app=geth || echo "$(YELLOW)Metrics server not available$(NC)"

backup: ## Backup chain data
	@echo "$(BLUE)Starting backup...$(NC)"
	@bash scripts/backup-chaindata.sh

clean: ## Remove deployment
	@echo "$(YELLOW)WARNING: This will delete all resources in $(NAMESPACE) namespace$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		kubectl delete -f kubernetes/ethereum/ --ignore-not-found=true; \
		kubectl delete -f kubernetes/observability/ --ignore-not-found=true; \
		kubectl delete namespace $(NAMESPACE) --ignore-not-found=true; \
		echo "$(GREEN)Cleanup complete$(NC)"; \
	else \
		echo "$(BLUE)Cleanup cancelled$(NC)"; \
	fi

clean-all: clean cluster-delete ## Remove everything including cluster

info: ## Show cluster and deployment info
	@echo "$(BLUE)Cluster Information:$(NC)"
	@kubectl cluster-info
	@echo ""
	@echo "$(BLUE)Current Context:$(NC)"
	@kubectl config current-context
	@echo ""
	@echo "$(BLUE)Nodes:$(NC)"
	@kubectl get nodes
	@echo ""
	@echo "$(BLUE)Storage Classes:$(NC)"
	@kubectl get storageclass

update-config: ## Update ConfigMap with new values
	@echo "$(BLUE)Updating configuration...$(NC)"
	@kubectl create configmap geth-config \
		--from-literal=NETWORK=$(NETWORK) \
		--namespace=$(NAMESPACE) \
		--dry-run=client -o yaml | kubectl apply -f -
	@kubectl rollout restart statefulset/geth -n $(NAMESPACE)

# Terraform targets
tf-init: ## Initialize Terraform
	@cd terraform/eks && terraform init

tf-plan: ## Plan Terraform changes
	@cd terraform/eks && terraform plan

tf-apply: ## Apply Terraform changes
	@cd terraform/eks && terraform apply

tf-destroy: ## Destroy Terraform resources
	@cd terraform/eks && terraform destroy

tf-output: ## Show Terraform outputs
	@cd terraform/eks && terraform output

# Development
dev-setup: cluster-create deploy deploy-observability ## Complete dev environment setup
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "$(BLUE)Access RPC:$(NC) make rpc"
	@echo "$(BLUE)Access Grafana:$(NC) make grafana"
	@echo "$(BLUE)View logs:$(NC) make logs"

quick-test: cluster-create deploy ## Quick test deployment
	@echo "$(BLUE)Waiting for pod to be ready...$(NC)"
	@kubectl wait --for=condition=ready pod -l app=geth -n $(NAMESPACE) --timeout=10m || true
	@make status
	@make logs-previous || true

.DEFAULT_GOAL := help
