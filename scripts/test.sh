#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-web3}"
OBSERVABILITY_NS="observability"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

test_case() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing: $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "Command failed: $command"
        ((FAILED++))
        return 1
    fi
}

echo -e "${BLUE}=== Running Tests ===${NC}"
echo ""

# Infrastructure Tests
echo -e "${BLUE}[Infrastructure]${NC}"
test_case "Namespace 'web3' exists" "kubectl get namespace $NAMESPACE"
test_case "Namespace 'observability' exists" "kubectl get namespace $OBSERVABILITY_NS"

# Workload Tests
echo -e "${BLUE}[Ethereum Node]${NC}"
test_case "StatefulSet exists" "kubectl get statefulset/geth -n $NAMESPACE"
test_case "Service exists" "kubectl get service/geth -n $NAMESPACE"
test_case "PVC bound" "kubectl get pvc -n $NAMESPACE | grep -q Bound"
test_case "Pod is running" "kubectl get pod -n $NAMESPACE -l app=geth --field-selector=status.phase=Running | grep -q geth"
test_case "ConfigMap loaded" "kubectl get configmap/geth-config -n $NAMESPACE"
test_case "NetworkPolicy active" "kubectl get networkpolicy/geth-network-policy -n $NAMESPACE"

# Observability Tests
echo -e "${BLUE}[Observability]${NC}"
test_case "Prometheus deployed" "kubectl get deployment/prometheus -n $OBSERVABILITY_NS"
test_case "Grafana deployed" "kubectl get deployment/grafana -n $OBSERVABILITY_NS"
test_case "Prometheus Service active" "kubectl get svc/prometheus -n $OBSERVABILITY_NS"
test_case "Grafana Service active" "kubectl get svc/grafana -n $OBSERVABILITY_NS"

# Functional Tests (only if pod is ready)
if kubectl get pod -n $NAMESPACE -l app=geth --field-selector=status.phase=Running | grep -q geth; then
    echo -e "${BLUE}[Functional]${NC}"
    
    # Wait for RPC port
    echo "Waiting for RPC port..."
    kubectl wait --for=condition=ready pod -l app=geth -n "$NAMESPACE" --timeout=60s >/dev/null 2>&1 || true

    # Port forward in background
    kubectl port-forward -n "$NAMESPACE" svc/geth 18545:8545 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 5
    
    # Test RPC
    RPC_RES=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:18545)
    if [[ $RPC_RES == *"result"* ]]; then
        echo -e "RPC Check: ${GREEN}PASS${NC}"
        ((PASSED++))
    else
        echo -e "RPC Check: ${RED}FAIL${NC}"
        echo "Response: $RPC_RES"
        ((FAILED++))
    fi
    
    # Kill port forward
    kill $PF_PID
fi

# Summary
echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC} ($PASSED/$((PASSED+FAILED)))"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC} (Passed: $PASSED, Failed: $FAILED)"
    exit 1
fi
