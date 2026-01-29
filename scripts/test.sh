#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-web3}"

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
        ((FAILED++))
        return 1
    fi
}

echo -e "${BLUE}=== Running Tests ===${NC}"
echo ""

# Test 1: Namespace exists
test_case "Namespace exists" "kubectl get namespace $NAMESPACE"

# Test 2: StatefulSet exists
test_case "StatefulSet exists" "kubectl get statefulset/geth -n $NAMESPACE"

# Test 3: Service exists
test_case "Service exists" "kubectl get service/geth -n $NAMESPACE"

# Test 4: PVC exists
test_case "PVC exists" "kubectl get pvc -n $NAMESPACE | grep -q data-geth"

# Test 5: Pod is running
test_case "Pod is running" "kubectl get pod -n $NAMESPACE -l app=geth | grep -q Running"

# Test 6: ConfigMap exists
test_case "ConfigMap exists" "kubectl get configmap/geth-config -n $NAMESPACE"

# Test 7: Secrets exist
test_case "Secrets exist" "kubectl get secret/geth-secrets -n $NAMESPACE"

# Test 8: NetworkPolicy exists
test_case "NetworkPolicy exists" "kubectl get networkpolicy/geth-network-policy -n $NAMESPACE"

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
