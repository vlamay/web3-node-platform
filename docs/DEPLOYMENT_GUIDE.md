# Deployment Guide

This guide describes how to deploy the Web3 Node Platform on AWS EKS.

## Prerequisites

1. **AWS Actions:**
   - AWS CLI configured with permissions
   - Terraform v1.6+
   - kubectl
   - Helm

2. **Access:**
   - Permissions to create VPC, EKS, IAM roles
   - Permissions to create S3 buckets

## Step 1: Infrastructure Deployment (Terraform)

1. **Initialize Terraform:**
   ```bash
   cd terraform/eks
   terraform init
   ```

2. **Plan (Dev Environment):**
   ```bash
   terraform plan -var-file="envs/dev.tfvars" -out=tfplan
   ```

3. **Apply:**
   ```bash
   terraform apply tfplan
   ```

4. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --name web3-node-dev --region us-east-1
   ```

## Step 2: Kubernetes Components Deployment

1. **Create Namespaces:**
   ```bash
   kubectl create namespace web3
   kubectl create namespace observability
   ```

2. **Deploy Security:**
   ```bash
   kubectl apply -f kubernetes/security/rbac.yaml
   kubectl apply -f kubernetes/security/network-policy.yaml
   ```

3. **Deploy Geth Node:**
   
   **Option A: Plain Manifests (Dev)**
   ```bash
   kubectl apply -f kubernetes/ethereum/
   ```

   **Option B: Kustomize (Recommended)**
   ```bash
   kubectl apply -k kubernetes/overlays/dev
   ```

4. **Deploy Observability Stack:**
   ```bash
   kubectl apply -f kubernetes/observability/
   ```
   *Alternative: Use `scripts/monitoring-setup.sh` to install via Helm.*

## Step 3: Validation

1. **Check Pod Status:**
   ```bash
   kubectl get pods -n web3
   kubectl get pods -n observability
   ```

2. **Run Validation Script:**
   ```bash
   ./scripts/validate-config.sh
   ```

3. **Test RPC Endpoint:**
   First, port-forward the Geth service:
   ```bash
   kubectl port-forward -n web3 svc/geth 8545:8545
   ```
   
   Then run the test script in another terminal:
   ```bash
   ./scripts/rpc-test.sh
   ```

## Step 4: Monitoring

1. **Access Grafana:**
   ```bash
   kubectl port-forward -n observability svc/grafana 3000:3000
   ```
   Open http://localhost:3000 (User: admin, default password in manifest).

2. **View Dashboards:**
   - Go to Dashboards -> General -> Ethereum Geth Node Metrics
   - Verify that Peer Count > 0 and Block Height is increasing

## Step 5: Clean Up

To destroy the environment:

1. **Delete Kubernetes Resources:**
   ```bash
   kubectl delete -k kubernetes/overlays/dev
   ```

2. **Destroy Infrastructure:**
   ```bash
   cd terraform/eks
   terraform destroy -var-file="envs/dev.tfvars"
   ```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
