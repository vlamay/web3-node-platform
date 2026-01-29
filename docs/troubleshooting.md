# Troubleshooting Guide

## Common Issues

### 1. Geth Pod Pending

**Symptoms:**
- Pod status stays in `Pending`
- Events show `SchedulingFailed`

**Possible Causes:**
- **Insufficient Resources:** The cluster doesn't have enough CPU/Memory.
- **PVC Binding:** PersistentVolumeClaim cannot bind to a Volume.
- **Node Taints:** Nodes have taints that the pod doesn't tolerate.

**Solutions:**
- Check node capacity: `kubectl describe node`
- Check PVC status: `kubectl get pvc -n web3`
- If using specific nodes, ensure `nodeSelector` or `affinity` matches available nodes.
- Check storage class provisioner: `kubectl get sc`

### 2. Geth Not Syncing

**Symptoms:**
- `eth_syncing` returns `false` but block number is 0 or very old.
- `p2p_peers` metric is 0.

**Possible Causes:**
- **Network Policy:** Blocking P2P traffic (port 30303).
- **DNS Issues:** Cannot resolve bootnodes.
- **Time Sync:** System time skew.

**Solutions:**
- Check logs: `kubectl logs -n web3 statefulset/geth`
- Verify network policy allows egress on 30303.
- Check peer count: `curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://dlo-rpc:8545`
- Add bootnodes manually via `EXTRA_FLAGS` in ConfigMap.

### 3. Terraform Errors

**Error: "Duplicate required providers"**
- **Cause:** Provider defined in multiple files.
- **Fix:** Keep provider cleanup in `main.tf` and remove from others.

**Error: "Error acquiring the state lock"**
- **Cause:** Previous run failed or is running.
- **Fix:** 
  - Check DynamoDB table for locks.
  - Or run `terraform force-unlock <LOCK_ID>` (use with caution).

### 4. Prometheus Not Scraping

**Symptoms:**
- Grafana dashboards are empty.
- Prometheus targets show "Down" or are missing.

**Possible Causes:**
- **Annotations Missing:** Pods missing `prometheus.io/scrape: "true"`.
- **Network Policy:** Blocking ingress to 6060.
- **Service Discovery:** RBAC permissions missing for Prometheus.

**Solutions:**
- Check Prometheus targets: Port-forward 9090 and go to Status -> Targets.
- Verify pod annotations: `kubectl get pod -n web3 geth-0 -o yaml`
- Check Prometheus logs: `kubectl logs -n observability deployment/prometheus`

### 5. High Resource Usage / OOMKilled

**Symptoms:**
- Pod restarts frequently with OOMKilled.
- High `container_cpu_throttling_seconds_total`.

**Solutions:**
- Increase limits in `kustomization.yaml` or `geth-statefulset.yaml`.
- Reduce `CACHE` size in ConfigMap.
- Use `m5.xlarge` or larger instances for production.

---

## Debugging Commands Cheat Sheet

**Logs:**
```bash
# Get last 100 lines
kubectl logs -n web3 statefulset/geth --tail=100

# Stream logs
kubectl logs -n web3 statefulset/geth -f
```

**Shell Access:**
```bash
# Enter container
kubectl exec -it -n web3 geth-0 -- sh

# Attach to Geth JS console
kubectl exec -it -n web3 geth-0 -- geth attach /data/geth.ipc
```

**Network Debugging:**
```bash
# Run a temporary debug pod
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash

# Test connectivity
nc -zv geth.web3.svc.cluster.local 8545
```
