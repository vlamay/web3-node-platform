#!/bin/bash
# monitoring-setup.sh - Install and configure monitoring stack using Helm

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="observability"

echo -e "${BLUE}Setting up monitoring stack...${NC}"

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus Operator (alternative to manual deployment)
echo -e "${BLUE}Installing Prometheus Operator...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace "$NAMESPACE" \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set grafana.adminPassword=admin \
    --wait

echo -e "${GREEN}✓${NC} Monitoring stack installed!"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n $NAMESPACE svc/prometheus-grafana 3000:80"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward -n $NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090"
