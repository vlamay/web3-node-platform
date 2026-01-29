# Logging Documentation (Loki & Promtail)

This guide describes the centralized logging architecture using the **Grafana Loki** stack.

## 🏗️ Architecture

Logs are collected from all containers by **Promtail** (running as a DaemonSet) and pushed to **Loki** for storage and indexing.

- **Collector**: Promtail (scrapes `/var/log/pods`)
- **Storage**: Loki (indexed by labels like `namespace`, `pod`, `app`)
- **Frontend**: Grafana (Explore view)

---

## 🚀 Setup Instructions

### 1. Add Grafana Repository
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### 2. Install Loki
```bash
helm install loki grafana/loki --namespace observability --values kubernetes/logging/loki-values.yaml
```

### 3. Install Promtail
```bash
helm install promtail grafana/promtail --namespace observability --set loki.serviceName=loki
```

---

## 🔍 querying Logs

Open Grafana, go to **Explore**, and select the **Loki** data source.

### Common Queries

**View all Geth logs:**
```logql
{app="geth"}
```

**Filter by error logs:**
```logql
{app="geth"} |= "ERROR"
```

**Count errors per minute:**
```logql
count_over_time({app="geth"} |= "ERROR" [1m])
```

---

## 📂 Retention Policy

- **Default Retention**: 7 days.
- **Storage**: EBS volume (`gp3`) attached to the Loki pod.
- **Volume Size**: 20Gi (configurable in `loki-values.yaml`).

> [!TIP]
> Use the **LogQL** language in Grafana to build powerful dashboards summarizing node warnings, network drops, and peer connection issues.
