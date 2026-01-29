# Production Deployment Scenario

This guide walks through a real-world production deployment of an Ethereum Mainnet node on AWS EKS.

## 🎯 Scenario Overview

**Goal**: Deploy a highly-available Ethereum Mainnet full node on AWS for production use.

**Requirements**:
- 99.9% uptime
- Full chain sync (Mainnet)
- 3 replicas for HA
- Automated backups
- Complete observability

**Estimated Monthly Cost**: ~$800-1200 USD
- EKS Cluster: ~$70
- EC2 Nodes (3x r5.xlarge): ~$500
- EBS Storage (3x 1TB gp3): ~$300
- Data Transfer: ~$50
- Backups (S3): ~$30

---

## 📋 Step-by-Step Deployment

### Phase 1: Infrastructure Provisioning (30 minutes)

```bash
# Clone repository
git clone https://github.com/vlamay/web3-node-platform.git
cd web3-node-platform

# Configure AWS credentials
export AWS_PROFILE=production
export AWS_REGION=us-east-1

# Deploy infrastructure
cd terraform/eks
terraform init
terraform apply -var-file=envs/prod.tfvars

# Expected output:
# - VPC with 3 AZs
# - EKS cluster (v1.28)
# - Node group (3x r5.xlarge)
# - gp3 storage class
# - Velero S3 bucket
```

### Phase 2: Kubernetes Setup (15 minutes)

```bash
# Connect to cluster
aws eks update-kubeconfig --name web3-node-prod --region us-east-1

# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace observability --create-namespace

# Install Velero for backups
velero install \
  --provider aws \
  --bucket web3-node-backups-prod \
  --secret-file ./velero-credentials \
  --use-volume-snapshots=true \
  --backup-location-config region=us-east-1

# Install ArgoCD for GitOps
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Phase 3: Deploy Geth Node (10 minutes)

```bash
# Deploy using Kustomize overlay
kubectl apply -k kubernetes/overlays/prod

# Verify deployment
kubectl get statefulset -n web3
kubectl get pvc -n web3

# Expected output:
# NAME   READY   AGE
# geth   0/3     30s
```

### Phase 4: Monitor Sync Progress (6-12 hours)

**Initial sync** for Mainnet can take 6-12 hours with snap sync.

```bash
# Check sync status
kubectl exec -n web3 geth-0 -- sh -c \
  "HOME=/data geth attach --exec 'eth.syncing' /data/geth.ipc"

# Expected output (syncing):
# {
#   currentBlock: 5234567,
#   highestBlock: 18900000,
#   ...
# }

# When fully synced, returns: false
```

**Monitor via Grafana**:
```bash
kubectl port-forward -n observability svc/prometheus-grafana 3000:80
# Open http://localhost:3000
# Login: admin / prom-operator
# Navigate to Ethereum Node dashboard
```

### Phase 5: Validation & Health Checks (5 minutes)

```bash
# Test RPC endpoint
kubectl port-forward -n web3 svc/geth 8545:8545

curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Expected: {"jsonrpc":"2.0","id":1,"result":"0x120c8a0"}

# Check peer count
kubectl exec -n web3 geth-0 -- sh -c \
  "HOME=/data geth attach --exec 'net.peerCount' /data/geth.ipc"
# Expected: 50-100 peers
```

---

## 🔄 Day 2 Operations

### Backups
- **Automated**: Velero runs daily at 01:00 UTC
- **Manual**: `velero backup create web3-manual --include-namespaces web3`

### Scaling
```bash
# Scale to 5 replicas
kubectl patch statefulset geth -n web3 -p '{"spec":{"replicas":5}}'
```

### Updates
```bash
# Update Geth version in statefulset
kubectl set image statefulset/geth geth=ethereum/client-go:v1.15.0 -n web3
kubectl rollout status statefulset/geth -n web3
```

### Monitoring Alerts
Key alerts configured in Prometheus:
- `EthNodeDown`: Node unreachable for 5min
- `EthSyncStalled`: No new blocks for 5min
- `EthLowPeerCount`: <5 peers
- `EthHighDiskUsage`: >85% disk usage

---

## 💰 Cost Optimization Tips

1. **Use Spot Instances** for non-critical dev/test (70% savings)
2. **Enable Cluster Autoscaler** to scale down during low usage
3. **Monitor S3 Lifecycle** for backup retention (30 days recommended)
4. **Use Reserved Instances** for predictable workloads (40% savings)

---

## 📊 Expected Performance

| Metric | Target | Actual |
|--------|--------|--------|
| Sync Time (Mainnet) | <12h | ~8-10h |
| RPC Latency (p95) | <100ms | ~50ms |
| Peer Count | 50+ | 75-100 |
| Uptime | 99.9% | 99.95% |

**Total Time to Production**: ~8-14 hours (including sync)
