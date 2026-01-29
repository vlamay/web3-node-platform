# Cost Optimization & Governance Guide

This guide describes how to manage costs and governance for the Web3 Node Platform on AWS.

## 💰 Cost Control Strategies

### 1. Environment-Specific Sizing
We use different instance types and scaling limits per environment to optimize spend.

| Env | Instance Type | Capacity | Purpose |
|-----|---------------|----------|---------|
| **Dev** | `t3.medium` | 1-3 nodes | Functional testing |
| **Stage** | `t3.large` | 2-5 nodes | Integration testing |
| **Prod** | `r5.xlarge` | 3-10 nodes | High-availability production |

### 2. Spot Instances
For non-critical workloads or temporary test environments, use Spot instances in Terraform:
```hcl
capacity_type = "SPOT"
```

### 3. EBS Management
- Use **gp3** volumes instead of gp2 for 20% lower cost per GB.
- Set `force_destroy = false` on production backup buckets to prevent accidental data loss.

---

## 🏷️ Mandatory Tagging Policy

All AWS resources are tagged using the following mandatory keys for cost allocation:

- `Environment`: (dev, staging, prod)
- `Project`: web3-node-platform
- `ManagedBy`: terraform
- `Owner`: <your-name/team>

### Implementation in Terraform
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "web3-node-platform"
    ManagedBy   = "terraform"
  }
}
```

---

## 📈 Monitoring Spend

1. **AWS Cost Explorer**: Create a report filtered by the `Project: web3-node-platform` tag.
2. **Budgets**: Set up an AWS Budget for each environment to receive alerts when spend exceeds 80% of forecasted.
3. **Cluster Autoscaler**: Enabled by default to scale down nodes when pods are deleted, saving costs during idle periods.
