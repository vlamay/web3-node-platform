# Troubleshooting Guide

This guide covers common issues encountered when deploying and operating the Web3 Node Platform.

## 🚨 Critical Conflicts

### 1. Environment Variable Shadowing (`GETH_PORT`)
**Symptoms**: Geth fails to start with error: `could not parse "tcp://..." as int value from environment variable "GETH_PORT"`.
**Cause**: Kubernetes injects `GETH_PORT` as a URL string because the service is named `geth`. This conflicts with Geth's internal port flag.
**Fix**: `enableServiceLinks: false` is set in the Pod spec to prevent this injection.

---

## 📦 Pod Issues

### 1. `CrashLoopBackOff` during Initialization
**Symptoms**: Container `init-permissions` fails with `Operation not permitted`.
**Cause**: Some storage drivers (like Kind's local-path) do not allow `chown` by root.
**Fix**: Rely on `fsGroup: 1000` in the security context instead of the init container.

### 2. `Pending` Pod
**Symptoms**: Pod stuck in `Pending` state.
**Fixes**:
- Check events: `make events`
- Verify StorageClass exists: `kubectl get sc`
- Check resource availability (CPU/Memory): `kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu`

---

## ⛓️ Blockchain Sync Issues

### 1. Node Finds No Peers
**Symptoms**: `net.peerCount` stays 0 for >30 minutes.
**Fixes**:
- Check NetworkPolicy: Ensure P2P ports (30303) are open.
- Increase peer limit: `make deploy MAX_PEERS=100`
- Check logs for "P2P networking" messages.

### 2. Slow Sync
**Symptoms**: Node is syncing but very slowly.
**Fixes**:
- Ensure you have high-performance storage (AWS `gp3` with 16000 IOPS recommended for Mainnet).
- Increase cache size: `make deploy CACHE_SIZE=4096`
- Check CPU throttling: `make top`

---

## 📊 Observability Issues

### 1. Manifests fail to apply (CRD error)
**Symptoms**: `no matches for kind "ServiceMonitor"`.
**Cause**: Prometheus Operator CRDs are not installed.
**Fix**: Install the `kube-prometheus-stack` via Helm as described in [Deployment Guide](deployment-guide.md).

### 2. No metrics in Grafana
**Symptoms**: Dashboard shows "No data".
**Fixes**:
- Verify Geth metrics endpoint: `curl localhost:6060/debug/metrics/prometheus`
- Check ServiceMonitor labels: Must match Prometheus selector labels.

---

## 💾 Storage Issues

### 1. PVC fails to bind
**Symptoms**: PVC stuck in `Pending`.
**Cause**: `WaitFirstConsumer` mode (standard in some SCs). Pod must be scheduled first.
**Fix**: Ensure your node selector/affinity allows the pod to be scheduled.

---

## 🔍 Investigation Toolkit

### Essential Commands
```bash
# Detailed pod info
make describe

# Tail logs
make logs

# Last 50 events
kubectl get events -n web3 --sort-by='.lastTimestamp' | Select-Object -Last 50

# Check process inside container
kubectl top pod -n web3
```
