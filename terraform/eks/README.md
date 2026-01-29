# AWS EKS Terraform Module for Web3 Node Platform

This directory contains Terraform configuration for deploying an AWS EKS cluster optimized for running Ethereum nodes.

## Features

- **VPC**: Multi-AZ VPC with public and private subnets
- **EKS Cluster**: Kubernetes 1.28+ with managed node groups
- **Node Configuration**: Tainted nodes for blockchain workloads
- **Storage**: gp3 StorageClass with high IOPS (16000) and throughput (1000 MB/s)
- **Security**: Private subnets, NAT gateway, security groups
- **Addons**: EBS CSI Driver, VPC CNI, CoreDNS, kube-proxy

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.6.0
- kubectl

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform/eks
terraform init
```

### 2. Review and Customize Variables

Edit variables or create `terraform.tfvars`:

```hcl
# Basic Configuration
project_name = "web3-node"
environment  = "dev"
aws_region   = "us-east-1"

# Network
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS Cluster
kubernetes_version = "1.28"

# Node Configuration
node_instance_types = ["m5.2xlarge"]  # 8 vCPU, 32 GB RAM
node_desired_size   = 1
node_min_size       = 1
node_max_size       = 3
node_disk_size      = 100  # GB

# Storage for Ethereum data
eth_data_storage_gi = 200  # GiB for Sepolia

# Cost Optimization
single_nat_gateway = true  # Use single NAT gateway (cheaper)
```

### 3. Plan and Apply

```bash
# Review changes
terraform plan

# Apply configuration
terraform apply
```

This will take **15-20 minutes** to create all resources.

### 4. Configure kubectl

```bash
# Command will be in Terraform outputs
aws eks update-kubeconfig --region us-east-1 --name web3-node-dev

# Verify cluster access
kubectl get nodes
```

### 5. Deploy Web3 Platform

```bash
# Return to project root
cd ../..

# Deploy Ethereum node
make deploy NETWORK=sepolia
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│              AWS Region (us-east-1)              │
├─────────────────────────────────────────────────┤
│                                                   │
│  ┌─────────────────────────────────────────┐   │
│  │          VPC (10.0.0.0/16)               │   │
│  │                                           │   │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐│   │
│  │  │Public AZ1│  │Public AZ2│  │Public 3││   │
│  │  │  (IGW)   │  │  (IGW)   │  │ (IGW)  ││   │
│  │  └────┬─────┘  └──────────┘  └────────┘│   │
│  │       │                                  │   │
│  │  ┌────▼──────────────────────────────┐ │   │
│  │  │      NAT Gateway (Elastic IP)     │ │   │
│  │  └────┬──────────────────────────────┘ │   │
│  │       │                                  │   │
│  │  ┌────▼────┐  ┌─────────┐  ┌─────────┐│   │
│  │  │Private 1│  │Private 2│  │Private 3││   │
│  │  │         │  │         │  │         ││   │
│  │  │ ┌─────┐ │  │ ┌─────┐ │  │         ││   │
│  │  │ │ EKS │ │  │ │ EKS │ │  │         ││   │
│  │  │ │Node │ │  │ │Node │ │  │         ││   │
│  │  │ └─────┘ │  │ └─────┘ │  │         ││   │
│  │  └─────────┘  └─────────┘  └─────────┘│   │
│  │                                           │   │
│  │  Labels: workload=blockchain             │   │
│  │  Taints: blockchain-workload=true        │   │
│  └─────────────────────────────────────────┘   │
│                                                   │
│  ┌─────────────────────────────────────────┐   │
│  │         EKS Control Plane                 │   │
│  │  ┌────────────────────────────────────┐ │   │
│  │  │  • API Server                      │ │   │
│  │  │  • etcd                            │ │   │
│  │  │  • Controller Manager              │ │   │
│  │  │  • Scheduler                       │ │   │
│  │  └────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────┘   │
│                                                   │
│  Storage: gp3 (16000 IOPS, 1000 MB/s)          │
└─────────────────────────────────────────────────┘
```

## Node Groups

### Blockchain Nodes
- **Instance Type**: m5.2xlarge (8 vCPU, 32 GB RAM)
- **Labels**: 
  - `workload=blockchain`
  - `environment=<env>`
- **Taints**: 
  - `blockchain-workload=true:NoSchedule`
- **Disk**: 100 GB gp3 root volume
- **Autoscaling**: 1-3 nodes

To schedule pods on these nodes, add to your StatefulSet:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        workload: blockchain
      tolerations:
        - key: blockchain-workload
          operator: Equal
          value: "true"
          effect: NoSchedule
```

## Storage Classes

### gp3 (Default)
- **Provisioner**: ebs.csi.aws.com
- **Type**: gp3
- **IOPS**: 16,000 (maximum)
- **Throughput**: 1,000 MB/s (maximum)
- **Encryption**: Enabled
- **Volume Expansion**: Enabled

Perfect for blockchain workloads requiring high I/O performance.

## Cost Considerations

### Estimated Monthly Costs (us-east-1)

**Development (1 node)**:
- EKS Control Plane: ~$73/month
- m5.2xlarge (1 node): ~$280/month
- NAT Gateway: ~$32/month
- gp3 Storage (200 GB): ~$16/month
- **Total**: ~$401/month

**Production (3 nodes)**:
- EKS Control Plane: ~$73/month
- m5.2xlarge (3 nodes): ~$840/month
- NAT Gateway: ~$32/month
- gp3 Storage (600 GB): ~$48/month
- **Total**: ~$993/month

### Cost Optimization

1. **Single NAT Gateway**: Set `single_nat_gateway = true` (saves ~$32/node)
2. **Spot Instances**: Use EC2 Spot for non-production (60-90% savings on compute)
3. **Right-sizing**: Use `m5.xlarge` for testnets (4 vCPU, 16 GB)
4. **Auto-shutdown**: Stop nodes during off-hours using AWS Instance Scheduler

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

**Warning**: This will delete the EKS cluster and all associated resources. Ensure you've backed up any important data.

## Troubleshooting

### kubectl not connecting

```bash
# Update kubeconfig
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Check AWS credentials
aws sts get-caller-identity
```

### Nodes not joining cluster

```bash
# Check node group status
kubectl get nodes

# Check EKS console for errors
aws eks describe-nodegroup \
  --cluster-name <cluster> \
  --nodegroup-name blockchain-nodes
```

### Storage issues

```bash
# Verify EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi

# Check StorageClass
kubectl get storageclass
```

## Advanced Configuration

### Enable Cluster Autoscaler

```bash
# Install cluster autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit deployment to add cluster name
kubectl -n kube-system edit deployment cluster-autoscaler
```

### Add Monitoring

Install Prometheus and Grafana:

```bash
# Deploy observability stack
make deploy-observability
```

## Security Best Practices

1. **Private API Endpoint**: Set `endpoint_public_access = false` in production
2. **VPC Endpoints**: Add VPC endpoints for S3, ECR to avoid NAT gateway costs
3. **IAM Roles**: Use IRSA (IAM Roles for Service Accounts) for pod-level permissions
4. **Network Policies**: Already configured in `kubernetes/ethereum/networkpolicy.yaml`
5. **Secrets Encryption**: Enable EKS secrets encryption at rest
6. **Audit Logs**: CloudWatch Logs enabled for all control plane components

## Next Steps

- [Deploy Ethereum Node](../../docs/deployment-guide.md)
- [Configure Monitoring](../../docs/monitoring.md)
- [Security Best Practices](../../docs/security.md)
