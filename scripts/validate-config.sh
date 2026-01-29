#!/bin/bash
# validate-config.sh - Validate all configurations before deployment

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; ((WARNINGS++)); }
log_error() { echo -e "${RED}[✗]${NC} $1"; ((ERRORS++)); }

echo "=== Kubernetes Manifest Validation ==="
echo ""

# Validate all YAML files
for file in kubernetes/**/*.yaml; do
    if [ -f "$file" ]; then
        log_info "Validating $file..."
        if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
            log_success "$file is valid"
        else
            log_error "$file has errors"
            kubectl apply --dry-run=client -f "$file" 2>&1 | head -n 5
        fi
    fi
done

echo ""
echo "=== Terraform Validation ==="
echo ""

if command -v terraform &> /dev/null; then
    cd terraform/eks
    log_info "Validating Terraform configuration..."
    if terraform init -backend=false > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
        log_success "Terraform configuration is valid"
    else
        log_error "Terraform validation failed"
        terraform validate
    fi
    cd ../..
else
    log_warning "Terraform not installed, skipping validation"
fi

echo ""
echo "=== Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
    exit 1
fi

exit 0
