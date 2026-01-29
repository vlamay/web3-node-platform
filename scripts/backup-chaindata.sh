#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-web3}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/geth-chaindata-$TIMESTAMP.tar.gz"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Get pod name
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=geth -o jsonpath='{.items[0].metadata.name}')

if [[ -z "$POD_NAME" ]]; then
    log_error "No geth pod found in namespace $NAMESPACE"
    exit 1
fi

log_info "Creating backup of chaindata from pod: $POD_NAME"
log_info "Backup file: $BACKUP_FILE"

# Create tarball in pod
log_info "Creating tarball in pod (this may take a while)..."
kubectl exec -n $NAMESPACE $POD_NAME -- tar -czf /tmp/chaindata-backup.tar.gz -C /data .

# Get file size
SIZE=$(kubectl exec -n $NAMESPACE $POD_NAME -- du -sh /tmp/chaindata-backup.tar.gz | cut -f1)
log_info "Backup size: $SIZE"

# Copy backup from pod
log_info "Copying backup to local machine..."
kubectl cp $NAMESPACE/$POD_NAME:/tmp/chaindata-backup.tar.gz "$BACKUP_FILE"

# Cleanup temporary file in pod
log_info "Cleaning up temporary file in pod..."
kubectl exec -n $NAMESPACE $POD_NAME -- rm /tmp/chaindata-backup.tar.gz

log_success "Backup completed: $BACKUP_FILE"
log_info "To restore, use: kubectl cp $BACKUP_FILE $NAMESPACE/$POD_NAME:/tmp/ && kubectl exec -n $NAMESPACE $POD_NAME -- tar -xzf /tmp/chaindata-backup.tar.gz -C /data"
