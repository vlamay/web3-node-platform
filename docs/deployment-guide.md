# Deployment Guide

This guide provides step-by-step instructions for deploying the Web3 Node Platform across different environments.

## 📋 Prerequisites

Ensure you have the following tools installed:
- **Docker**: For local testing and container management
- **kubectl**: For interacting with Kubernetes clusters
- **kind**: (Local only) For creating local clusters
- **Terraform**: (Cloud only) For infrastructure provisioning
- **AWS CLI**: (Cloud only) For AWS access

---

## 🚀 Local Deployment (kind)

### 1. Create Cluster
```bash
make cluster-create
```
*Note: This uses `docs/kind-config.yaml` to map required ports.*

### 2. Deploy Platform
```bash
make deploy NETWORK=sepolia STORAGE_SIZE=10Gi
```

### 3. Verify Health
```bash
# Check pod status
make status

# View logs
make logs

# Check sync status
kubectl exec -n web3 geth-0 -- sh -c "HOME=/data geth attach --exec 'eth.syncing' /data/geth.ipc"
```

---

## ☁️ Cloud Deployment (AWS EKS)

### 1. Provision Infrastructure
```bash
cd terraform/eks
terraform init
terraform apply
```

### 2. Configure Access
```bash
aws eks update-kubeconfig --region <your-region> --name web3-node-dev
```

### 3. Deploy Platform
```bash
# Return to root
cd ../..
make deploy NETWORK=mainnet STORAGE_SIZE=1000Gi
```

---

## 📊 Observability Setup

> [!IMPORTANT]
> The observability stack (ServiceMonitor, PrometheusRule) requires the **Prometheus Operator** or **kube-stack-prometheus** to be installed in the cluster.

### 1. Install Prometheus Operator (if missing)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack --namespace observability --create-namespace
```

### 2. Deploy Metrics Configs
```bash
make deploy-observability
```

### 3. Access Dashboards
```bash
make grafana
# Login: admin / admin
```

---

## 🛠️ Configuration & Customization

### Resource Sizing
| Network | Storage | CPU (Request/Limit) | Memory (Request/Limit) |
|---------|---------|---------------------|------------------------|
| Sepolia | 100Gi   | 1.0 / 4.0 cores     | 4Gi / 8Gi              |
| Mainnet | 1000Gi  | 4.0 / 8.0 cores     | 16Gi / 32Gi            |

### Usage with Makefile
```bash
make deploy \
  NETWORK=mainnet \
  STORAGE_SIZE=1000Gi \
  CPU_LIMIT=8000m \
  MEMORY_LIMIT=32Gi
```

---

## 🔄 Post-Deployment Operations

### Backup Chaindata
```bash
make backup
```

### Health Monitoring
```bash
make healthcheck
```

### Scaling
```bash
make scale REPLICAS=3
```
