# Disaster Recovery & Backup Guide (Velero)

This guide outlines the strategy for backing up and restoring the Web3 Node Platform using **Velero**.

## 🛡️ Backup Strategy

We use Velero to perform daily snapshots of the Kubernetes namespace and the underlying EBS volumes (Service $+$ Chaindata).

- **Scope**: Full `web3` namespace (PVCs, Secrets, ConfigMaps, StatefulSets).
- **Frequency**: Daily at 01:00 UTC.
- **Retention**: 30 days.
- **Storage**: AWS S3 bucket with EBS Volume Snapshots.

---

## 🚀 Setup Instructions

### 1. Install Velero CLI
Download the Velero CLI from the [official releases](https://github.com/vmware-tanzu/velero/releases).

### 2. Install Velero in Cluster
```bash
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.7.0 \
    --bucket <your-s3-bucket> \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=true \
    --backup-location-config region=<your-region> \
    --snapshot-location-config region=<your-region>
```

### 3. Apply Backup Configurations
```bash
kubectl apply -f kubernetes/velero/velero-config.yaml
```

---

## 🔄 Recovery Procedures

### 1. List Available Backups
```bash
velero backup get
```

### 2. Restore Full Namespace
In case of accidental deletion or cluster migration:
```bash
velero restore create --from-backup geth-daily-backup-<timestamp>
```

### 3. Restore Specific PVC
To restore only the blockchain data to a specific point:
```bash
velero restore create --from-backup geth-daily-backup-<timestamp> --include-resources persistentvolumeclaims
```

---

## 📉 RTO/RPO Targets

| Metric | Target | Description |
|--------|--------|-------------|
| **RPO** (Recovery Point Objective) | 24 Hours | Maximum data loss since last daily backup. |
| **RTO** (Recovery Time Objective) | < 30 Minutes | Time to recreate resources and attach snapshots. |

> [!NOTE]
> For Ethereum nodes, the "recovery" also involves Geth catching up with the blocks generated since the snapshot was taken. This "sync catch-up" time depends on the RPO.
