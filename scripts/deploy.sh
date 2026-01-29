#!/bin/bash
set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-web3}"
NETWORK="${NETWORK:-sepolia}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
STORAGE_CLASS="${STORAGE_CLASS:-standard}"
STORAGE_SIZE="${STORAGE_SIZE:-100Gi}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check storage class
    if ! kubectl get storageclass "$STORAGE_CLASS" &> /dev/null; then
        log_warn "StorageClass '$STORAGE_CLASS' not found. Available storage classes:"
        kubectl get storageclass
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace
create_namespace() {
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace $NAMESPACE name=$NAMESPACE --overwrite
    log_success "Namespace ready"
}

# Deploy configuration
deploy_config() {
    log_info "Deploying configuration..."
    
    # Create ConfigMap
    kubectl create configmap geth-config \
        --from-literal=NETWORK=$NETWORK \
        --from-literal=SYNC_MODE=snap \
        --from-literal=HTTP_PORT=8545 \
        --from-literal=WS_PORT=8546 \
        --from-literal=METRICS_PORT=6060 \
        --from-literal=P2P_PORT=30303 \
        --from-literal=HTTP_API="eth,net,web3,txpool" \
        --from-literal=WS_API="eth,net,web3" \
        --from-literal=HTTP_CORS_ORIGINS="*" \
        --from-literal=HTTP_VHOSTS="*" \
        --from-literal=CACHE_SIZE=2048 \
        --from-literal=MAX_PEERS=50 \
        --from-literal=LOG_LEVEL=info \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply secrets
    kubectl apply -f kubernetes/ethereum/geth-secrets.yaml
    
    log_success "Configuration deployed"
}

# Update StatefulSet with storage parameters
update_statefulset() {
    log_info "Updating StatefulSet with storage parameters..."
    
    local temp_file=$(mktemp)
    cp kubernetes/ethereum/geth-statefulset.yaml "$temp_file"
    
    # Update storage class and size
    sed -i "s/storageClassName: standard/storageClassName: $STORAGE_CLASS/g" "$temp_file" 2>/dev/null ||     sed -i '' "s/storageClassName: standard/storageClassName: $STORAGE_CLASS/g" "$temp_file"
    sed -i "s/storage: 100Gi/storage: $STORAGE_SIZE/g" "$temp_file" 2>/dev/null || \
    sed -i '' "s/storage: 100Gi/storage: $STORAGE_SIZE/g" "$temp_file"
    
    kubectl apply -f "$temp_file"
    rm "$temp_file"
    
    log_success "StatefulSet updated"
}

# Deploy Ethereum node
deploy_ethereum() {
    log_info "Deploying Ethereum node (Network: $NETWORK)..."
    
    # Apply service first
    kubectl apply -f kubernetes/ethereum/geth-service.yaml
    
    # Apply StatefulSet
    update_statefulset
    
    # Apply NetworkPolicy
    kubectl apply -f kubernetes/ethereum/networkpolicy.yaml
    
    log_success "Ethereum node deployment initiated"
}

# Wait for deployment
wait_for_deployment() {
    log_info "Waiting for StatefulSet to be ready (this may take several minutes)..."
    
    if kubectl rollout status statefulset/geth \
        --namespace=$NAMESPACE \
        --timeout=15m; then
        log_success "StatefulSet is ready"
    else
        log_error "StatefulSet rollout failed"
        log_info "Checking pod status..."
        kubectl get pods -n $NAMESPACE -l app=geth
        log_info "Checking pod logs..."
        kubectl logs -n $NAMESPACE -l app=geth --tail=50
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    local pod_name=$(kubectl get pod -n $NAMESPACE -l app=geth -o jsonpath='{.items[0].metadata.name}')
    
    if [[ -z "$pod_name" ]]; then
        log_error "No pods found"
        exit 1
    fi
    
    log_info "Pod: $pod_name"
    kubectl get pod $pod_name -n $NAMESPACE
    
    log_info "Checking node connectivity (this may take a while)..."
    sleep 30
    
    if kubectl exec -n $NAMESPACE $pod_name -- geth attach --exec "net.peerCount" /data/geth.ipc 2>/dev/null; then
        log_success "Node is responding"
    else
        log_warn "Node is still initializing..."
    fi
}

# Display access information
display_access_info() {
    echo ""
    echo "========================================="
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo "========================================="
    echo ""
    echo "Network: $NETWORK"
    echo "Namespace: $NAMESPACE"
    echo "Environment: $ENVIRONMENT"
    echo ""
    echo "Access RPC endpoint:"
    echo "  kubectl port-forward -n $NAMESPACE svc/geth 8545:8545"
    echo ""
    echo "Access WebSocket endpoint:"
    echo "  kubectl port-forward -n $NAMESPACE svc/geth 8546:8546"
    echo ""
    echo "View logs:"
    echo "  kubectl logs -n $NAMESPACE -l app=geth -f"
    echo ""
    echo "Check status:"
    echo "  make status"
    echo ""
    echo "Run health check:"
    echo "  make healthcheck"
    echo ""
    echo "========================================="
}

# Main deployment flow
main() {
    echo "========================================="
    echo "  Web3 Node Platform Deployment"
    echo "========================================="
    echo ""
    echo "Configuration:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Namespace: $NAMESPACE"
    echo "  Network: $NETWORK"
    echo "  Storage Class: $STORAGE_CLASS"
    echo "  Storage Size: $STORAGE_SIZE"
    echo ""
    
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    check_prerequisites
    echo ""
    
    create_namespace
    echo ""
    
    deploy_config
    echo ""
    
    deploy_ethereum
    echo ""
    
    wait_for_deployment
    echo ""
    
    verify_deployment
    echo ""
    
    display_access_info
}

main "$@"
