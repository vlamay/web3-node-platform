#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-web3}"
RPC_URL="${RPC_URL:-http://localhost:8545}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Ethereum Node Health Check ===$" {NC}"

check_rpc() {
    echo -n "Checking RPC connectivity... "
    if result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
        $RPC_URL 2>/dev/null | jq -r '.result' 2>/dev/null); then
        echo -e "${GREEN}✓${NC}"
        echo "  Client: $result"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

check_sync_status() {
    echo -n "Checking sync status... "
    if result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        $RPC_URL 2>/dev/null); then
        echo -e "${GREEN}✓${NC}"
        if echo "$result" | jq -e '.result == false' > /dev/null 2>&1; then
            echo -e "  Status: ${GREEN}Fully Synced${NC}"
        else
            echo -e "  Status: ${YELLOW}Syncing${NC}"
            echo "$result" | jq '.result'
        fi
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

check_peer_count() {
    echo -n "Checking peer count... "
    if result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        $RPC_URL 2>/dev/null | jq -r '.result' 2>/dev/null); then
        peers=$((16#${result#0x}))
        echo -e "${GREEN}✓${NC}"
        if [ $peers -ge 5 ]; then
            echo -e "  Peers: ${GREEN}$peers${NC}"
        elif [ $peers -gt 0 ]; then
            echo -e "  Peers: ${YELLOW}$peers${NC} (low)"
        else
            echo -e "  Peers: ${RED}$peers${NC} (no peers!)"
        fi
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

check_block_number() {
    echo -n "Checking current block... "
    if result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        $RPC_URL 2>/dev/null | jq -r '.result' 2>/dev/null); then
        block=$((16#${result#0x}))
        echo -e "${GREEN}✓${NC}"
        echo "  Block: $block"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

check_gas_price() {
    echo -n "Checking gas price... "
    if result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}' \
        $RPC_URL 2>/dev/null | jq -r '.result' 2>/dev/null); then
        gas_price=$((16#${result#0x}))
        gas_gwei=$(awk "BEGIN {printf \"%.2f\", $gas_price / 1000000000}")
        echo -e "${GREEN}✓${NC}"
        echo "  Gas Price: $gas_gwei Gwei"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

main() {
    check_rpc || exit 1
    check_sync_status || exit 1
    check_peer_count || exit 1
    check_block_number || exit 1
    check_gas_price || exit 1
    
    echo ""
    echo -e "${GREEN}Health check passed!${NC}"
}

main "$@"
