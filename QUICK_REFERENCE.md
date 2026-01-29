# Web3 Node Platform - Quick Reference

## 🚀 Quick Commands

### Local Deployment (kind)
```bash
# Full setup
make cluster-create    # Create kind cluster
make deploy            # Deploy Ethereum node (Sepolia)
make status            # Check deployment status
make logs              # View logs

# One-command dev setup
make dev-setup         # Creates cluster + deploys everything

# Monitor
make healthcheck       # Check node health
make metrics           # Access metrics (http://localhost:6060)

# Cleanup
make clean             # Delete all resources
make cluster-delete    # Delete kind cluster
```

### Cloud Deployment (AWS EKS)
```bash
# Infrastructure
cd terraform/eks
terraform init
terraform apply        # ~15-20 minutes

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name web3-node-dev

# Deploy
cd ../..
make deploy NETWORK=sepolia STORAGE_SIZE=200Gi

# Cleanup
cd terraform/eks
terraform destroy
```

## 📊 Customization Variables

### Network Selection
```bash
make deploy NETWORK=sepolia    # Testnet (default)
make deploy NETWORK=mainnet    # Mainnet
```

### Resource Configuration
```bash
make deploy \
  STORAGE_SIZE=200Gi \         # Disk size
  CPU_REQUEST=1000m \          # Min CPU
  CPU_LIMIT=4000m \            # Max CPU
  MEMORY_REQUEST=4Gi \         # Min memory
  MEMORY_LIMIT=8Gi \           # Max memory
  CACHE_SIZE=4096 \            # Geth cache
  MAX_PEERS=100                # Max peers
```

### Storage Requirements by Network
- **Sepolia**: 100-200 GB
- **Goerli**: 200-300 GB  
- **Mainnet (snap)**: 800-1000 GB
- **Mainnet (full)**: 2+ TB

## 🔍 Debugging

### Pod Issues
```bash
make status                    # Get pod status
make describe                  # Detailed pod info
make events                    # Recent events
make logs                      # View logs
make logs-follow               # Follow logs
make shell                     # Shell into pod
```

### Resource Monitoring
```bash
make top                       # Resource usage
make metrics                   # Prometheus metrics
kubectl get pvc -n web3        # Check storage
```

### Common Issues

**Pod Pending**
```bash
# Check events
make events
# Usually: storage class not found or insufficient resources
```

**CrashLoopBackOff**
```bash
# Check logs
make logs
# Common: insufficient memory, sync mode issue
```

**Slow Sync**
```bash
# Check peer count
make healthcheck
# Increase peers if too low:
make deploy MAX_PEERS=100
```

## 📁 Project Structure

```
web3-node-platform/
├── kubernetes/
│   ├── base/                  # Namespaces
│   ├── ethereum/              # Geth manifests
│   └── observability/         # Prometheus, Grafana
├── terraform/
│   └── eks/                   # AWS EKS infrastructure
├── scripts/                   # Automation scripts
├── docs/                      # Documentation
├── .github/workflows/         # CI/CD pipelines
├── Makefile                   # Commands
└── README.md                  # Main documentation
```

## 🎯 Key Files

### Configuration
- `kubernetes/ethereum/geth-configmap.yaml` - Network, API config
- `kubernetes/ethereum/geth-secrets.yaml` - RPC secrets
- `kubernetes/ethereum/geth-statefulset.yaml` - Node deployment

### Scripts
- `scripts/deploy.sh` - Deployment automation
- `scripts/healthcheck.sh` - Node health checks
- `scripts/backup-chaindata.sh` - Backup utility
- `scripts/test.sh` - Resource validation

### Infrastructure
- `terraform/eks/variables.tf` - AWS configuration
- `terraform/eks/terraform.tfvars.example` - Config template

## 💡 Tips

### For Development
```bash
# Use smaller resources for testing
make deploy \
  STORAGE_SIZE=50Gi \
  CPU_LIMIT=1000m \
  MEMORY_LIMIT=2Gi
```

### For Production
```bash
# Use adequate resources for mainnet
make deploy \
  NETWORK=mainnet \
  STORAGE_SIZE=1000Gi \
  CPU_LIMIT=8000m \
  MEMORY_LIMIT=16Gi \
  CACHE_SIZE=8192
```

### Cost Optimization (AWS)
```bash
# Edit terraform/eks/terraform.tfvars
single_nat_gateway = true      # Save ~$32/month
node_instance_types = ["m5.xlarge"]  # Use smaller instance
```

### Monitoring Setup
```bash
# Deploy observability stack
make deploy-observability

# Port-forward Grafana
kubectl port-forward -n observability svc/grafana 3000:3000

# Access: http://localhost:3000
# Default credentials: admin/admin
```

## 📞 Getting Help

### Check Documentation
- Main README: `README.md`
- Terraform: `terraform/eks/README.md`
- Makefile help: `make help`

### Useful Commands
```bash
make help                      # List all commands
kubectl get all -n web3        # All resources
kubectl describe pod <pod> -n web3  # Pod details
kubectl logs <pod> -n web3 -f  # Live logs
```

### Common Makefile Targets
```
make install          # Install prerequisites
make validate         # Validate manifests
make deploy           # Deploy to Kubernetes
make status           # Check deployment
make logs             # View logs
make healthcheck      # Run health check
make backup           # Backup chaindata
make clean            # Delete resources
make tf-init          # Initialize Terraform
make tf-apply         # Apply Terraform
```

## 🔗 Links

- [Full Documentation](README.md)
- [Deployment Guide](docs/deployment-guide.md) *(to be created)*
- [Troubleshooting](docs/troubleshooting.md) *(to be created)*
- [Architecture](docs/architecture.md) *(to be created)*
- [Terraform README](terraform/eks/README.md)
- [Portfolio Summary](../brain/portfolio_summary.md)
