#!/bin/bash
# rpc-test.sh - Test Ethereum RPC endpoints

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

RPC_URL="${RPC_URL:-http://localhost:8545}"

echo "Testing RPC endpoint: $RPC_URL"
echo ""

# Test eth_blockNumber
echo -n "Testing eth_blockNumber... "
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    "$RPC_URL")

if echo "$RESPONSE" | grep -q "result"; then
    BLOCK_HEX=$(echo "$RESPONSE" | jq -r '.result')
    BLOCK_DEC=$((16#${BLOCK_HEX#0x}))
    echo -e "${GREEN}✓${NC} Current block: $BLOCK_DEC"
else
    echo -e "${RED}✗${NC} Failed"
    echo "$RESPONSE"
fi

# Test net_peerCount
echo -n "Testing net_peerCount... "
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
    "$RPC_URL")

if echo "$RESPONSE" | grep -q "result"; then
    PEERS_HEX=$(echo "$RESPONSE" | jq -r '.result')
    PEERS_DEC=$((16#${PEERS_HEX#0x}))
    echo -e "${GREEN}✓${NC} Peer count: $PEERS_DEC"
else
    echo -e "${RED}✗${NC} Failed"
fi

# Test eth_syncing
echo -n "Testing eth_syncing... "
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
    "$RPC_URL")

if echo "$RESPONSE" | grep -q "false"; then
    echo -e "${GREEN}✓${NC} Fully synced"
elif echo "$RESPONSE" | grep -q "currentBlock"; then
    echo -e "${GREEN}✓${NC} Syncing in progress"
    echo "$RESPONSE" | jq '.result'
else
    echo -e "${RED}✗${NC} Failed"
fi

echo ""
echo "RPC tests complete!"
