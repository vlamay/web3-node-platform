# Monitoring Documentation

The Web3 Node Platform comes with a built-in observability stack based on Prometheus and Grafana.

## 📊 Metrics Overview

The platform collects metrics from three layers:
1. **Blockchain Layer (Geth)**: Sync status, peer count, gas prices.
2. **Infrastructure Layer (Kubernetes)**: CPU/Memory usage, disk IOPS, network bandwidth.
3. **Application Layer (RPC)**: RPC latency, request volume, error rates.

## 🚨 Alerting Rules

We have pre-configured 20+ alerts in `prometheus-rules.yaml`:

### Critical Alerts (P1)
- **EthNodeDown**: Node is unreachable for >5 minutes.
- **EthSyncStalled**: Block height hasn't increased for 5 minutes.
- **EthLowPeerCount**: <5 peers connected (risk of fork/isolation).

### Performance Alerts (P2)
- **EthHighResourceUsage**: CPU or Memory > 90% of limits.
- **EthLowStorageSpace**: <15% of disk space remaining.
- **EthHighRPCLatency**: RPC responses taking > 1s (95th percentile).

## 📈 Grafana Dashboard

The custom dashboard (`ethereum-node.json`) provides real-time visualization:

- **Network Status**: Active peers, inbound/outbound traffic.
- **Blockchain Sync**: Current block vs. network block height.
- **RPC Performance**: Request rates and latency per method.
- **System Health**: CPU/Memory/Disk trends.

## 🛠️ Operations

### Manual Metrics Check
```bash
# Via Makefile
make metrics

# Direct curl
kubectl exec -n web3 geth-0 -- curl localhost:6060/debug/metrics/prometheus
```

### Accessing Dashboards
```bash
# Port-forward Grafana (default admin/admin)
make grafana
```

## 🔭 Future Improvements
- **Loki Integration**: Correlate logs with metric spikes.
- **Custom Exporters**: Add Beacon Chain metrics for Ethereum PoS support.
- **Anomaly Detection**: Dynamic alerting thresholds using Prometheus recording rules.
