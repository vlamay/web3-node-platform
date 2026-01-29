# GitOps Guide (ArgoCD)

This guide describes how to manage the Web3 Node Platform using a GitOps workflow with ArgoCD.

## 🏗️ Architecture

In a GitOps flow, Git is the single source of truth. Any change pushed to the `main` branch is automatically synchronized to the cluster by ArgoCD.

## 🚀 Getting Started

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Connect Your Repository
Apply the ArgoCD Application manifest:
```bash
kubectl apply -f gitops/argocd/app-web3-node.yaml
```

### 3. Access ArgoCD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
*Login with `admin` and the password from `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`*

---

## 🔄 Synchronization & Rollbacks

- **Auto-Sync**: Enabled by default. Any change in `kubernetes/` will be applied within minutes.
- **Self-Healing**: If a resource is deleted manually in the cluster, ArgoCD will recreate it.
- **Rollback**: To rollback, simply `git revert` the commit in Git. ArgoCD will sync the previous state.

## 📂 Repository Structure for GitOps

```bash
gitops/
└── argocd/
    └── app-web3-node.yaml    # Application definition
kubernetes/
├── base/                     # Core configs
├── ethereum/                 # Node manifests
└── observability/            # Metrics & Dashboards
```
