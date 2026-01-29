# Web3 Node Platform

[![CI Pipeline](https://github.com/vlamay/web3-node-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/vlamay/web3-node-platform/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Production-ready Kubernetes platform for deploying and monitoring Ethereum nodes (EVM-compatible chains) with Infrastructure as Code, comprehensive observability, and security best practices.

## 🌟 Features

- **🚀 Production-Ready**: StatefulSet architecture with persistent storage, health checks, and resource limits
- **📊 Observability**: Prometheus metrics, Grafana dashboards, and proactive alerting
- **🔒 Security**: NetworkPolicies, RBAC, Secret management, and non-root containers
- **🛠️ Infrastructure as Code**: Terraform modules for AWS EKS provisioning
- **🔄 CI/CD**: GitHub Actions for validation, security scanning, and automated deployment
- **📦 Multi-Network Support**: Sepolia, Goerli, Mainnet, and custom EVM chains
- **⚡ High Performance**: Optimized resource allocation and disk I/O configurations

## 📋 Prerequisites

- **Kubernetes**: 1.24+ (local: kind/minikube, cloud: EKS/GKE/AKS)
- **kubectl**: v1.24+
- **Storage**: 100GB+ for testnets, 1TB+ for mainnet
- **Optional**: Terraform 1.6+, Helm 3+, Docker

## 🚀 Quick Start

Choose your deployment path:

### Option 1: Local Deployment (kind) - Recommended for Testing

Perfect for development and testing without cloud costs.

```bash
# Clone repository
git clone https://github.com/vlamay/web3-node-platform.git
cd web3-node-platform

# Create local Kubernetes cluster
make cluster-create

# Deploy Ethereum node (Sepolia testnet)
make deploy NETWORK=sepolia

# Check deployment status
make status

# View logs
make logs
```

### Option 2: Cloud Deployment (AWS EKS) - Production Ready

For production workloads with high availability and scalability.

**Prerequisites**: AWS CLI configured with credentials

```bash
# 1. Provision EKS infrastructure (15-20 minutes)
cd terraform/eks
terraform init
terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name web3-node-dev

# 3. Deploy Ethereum node
cd ../..
make deploy NETWORK=sepolia

# 4. Verify deployment
make status
```

**Estimated Cost**: ~$400/month (dev), ~$1000/month (prod 3 nodes)  
See [terraform/eks/README.md](terraform/eks/README.md) for cost breakdown.

## 📊 Monitoring

Access monitoring dashboards:

```bash
# Port-forward Grafana
kubectl port-forward -n observability svc/grafana 3000:3000

# Port-forward Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090

# View metrics endpoint
make metrics
```

Default credentials:
- Grafana: admin / admin (change after first login)

## 🔧 Configuration

### Network Configuration

Edit `kubernetes/ethereum/geth-configmap.yaml`:

```yaml
data:
  NETWORK: "sepolia"      # Options: sepolia, mainnet, goerli
  SYNC_MODE: "snap"       # Options: snap, full, light
  HTTP_PORT: "8545"
  WS_PORT: "8546"
```

### Resource Allocation

Edit `kubernetes/ethereum/geth-statefulset.yaml`:

```yaml
resources:
  requests:
    cpu: "1000m"
    memory: "4Gi"
  limits:
    cpu: "4000m"
    memory: "8Gi"
```

### Storage

Edit `volumeClaimTemplates` in StatefulSet:

```yaml
resources:
  requests:
    storage: 100Gi    # Sepolia: 100Gi, Mainnet: 1Ti+
storageClassName: gp3  # Change to your StorageClass
```

Or use Makefile variables:

```bash
make deploy STORAGE_SIZE=200Gi
```

### Resource Limits

Customize CPU and memory via Makefile variables:

```bash
# Deploy with custom resources
make deploy \
  CPU_REQUEST=1000m \
  CPU_LIMIT=4000m \
  MEMORY_REQUEST=4Gi \
  MEMORY_LIMIT=8Gi \
  CACHE_SIZE=4096 \
  MAX_PEERS=100

# Deploy for mainnet with high resources
make deploy \
  NETWORK=mainnet \
  STORAGE_SIZE=1000Gi \
  CPU_LIMIT=8000m \
  MEMORY_LIMIT=16Gi
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐         ┌──────────────────┐          │
│  │ Namespace:  │         │  Namespace:       │          │
│  │   web3      │         │  observability    │          │
│  │             │         │                   │          │
│  │ ┌─────────┐ │         │  ┌──────────┐    │          │
│  │ │  Geth   │ │────────▶│  │Prometheus│    │          │
│  │ │StatefulSet│        │  │  Server   │    │          │
│  │ │         │ │  metrics│  └──────────┘    │          │
│  │ │ - RPC   │ │         │       │          │          │
│  │ │ - P2P   │ │         │       ▼          │          │
│  │ │ - WS    │ │         │  ┌──────────┐    │          │
│  │ └─────────┘ │         │  │ Grafana  │    │          │
│  │      │      │         │  │Dashboards│    │          │
│  │      ▼      │         │  └──────────┘    │          │
│  │ ┌─────────┐ │         │                   │          │
│  │ │   PVC   │ │         │  ┌──────────┐    │          │
│  │ │ (500GB) │ │         │  │AlertManager   │          │
│  │ └─────────┘ │         │  └──────────┘    │          │
│  └─────────────┘         └──────────────────┘          │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 📖 Documentation

- [**Deployment Guide**](docs/deployment-guide.md) - Detailed deployment instructions
- [**Architecture**](docs/architecture.md) - System design and components
- [**Troubleshooting**](docs/troubleshooting.md) - Common issues and solutions
- [**Monitoring**](docs/monitoring.md) - Observability setup and dashboards
- [**Security**](docs/security.md) - Security best practices

## 🛠️ Available Commands

```bash
# Deployment
make install          # Install dependencies
make validate         # Validate Kubernetes manifests
make deploy          # Deploy to Kubernetes
make clean           # Remove deployment

# Operations
make status          # Check deployment status
make logs            # View node logs
make exec            # Shell into node container
make metrics         # Port-forward metrics endpoint
make rpc             # Port-forward RPC endpoint

# Development
make lint            # Lint manifests
make test            # Run tests
```

## 🔒 Security Features

- **Network Policies**: Restrict traffic to/from node pods
- **Non-root Containers**: All containers run as non-root user
- **Secret Management**: Kubernetes Secrets for sensitive data
- **RBAC**: Role-based access control
- **Resource Limits**: Prevent resource exhaustion
- **Read-only Root Filesystem**: Where applicable
- **Security Scanning**: Automated Trivy scans in CI/CD

## 📈 Monitoring & Alerts

### Metrics Collected

- **Blockchain**: Block height, sync status, chain head age
- **Network**: Peer count, inbound/outbound connections, bandwidth
- **Performance**: RPC latency, transactions/sec, block processing time
- **Resources**: CPU, memory, disk usage, IOPS
- **Errors**: Failed RPC calls, sync errors, connection drops

### Pre-configured Alerts

- Node down for >5 minutes
- Block height lag >5 minutes
- Low peer count (<5 peers)
- High memory usage (>90%)
- Low disk space (<15%)

## 🧪 Testing

```bash
# Validate manifests
make validate

# Test on local kind cluster
kind create cluster --name test
make deploy NETWORK=sepolia
make test

# Clean up
kind delete cluster --name test
```

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [Ethereum](https://ethereum.org/) - Blockchain platform
- [Geth](https://geth.ethereum.org/) - Go Ethereum client
- [Prometheus](https://prometheus.io/) - Monitoring system
- [Grafana](https://grafana.com/) - Visualization platform

## 📞 Support

- 📧 Email: support@example.com
- 💬 Discord: [Join our server](https://discord.gg/example)
- 🐛 Issues: [GitHub Issues](https://github.com/vlamay/web3-node-platform/issues)

---

**Made with ❤️ for the Ethereum community**
