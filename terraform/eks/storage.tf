# gp3 StorageClass with increased IOPS for blockchain workloads
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    iops      = "16000"      # Max IOPS for gp3
    throughput = "1000"      # Max throughput in MB/s
    encrypted = "true"
    "csi.storage.k8s.io/fstype" = "ext4"
  }

  depends_on = [aws_eks_addon.ebs_csi]
}

# Tolerations for blockchain nodes (match StatefulSet taints)
resource "kubernetes_config_map_v1" "node_tolerations" {
  metadata {
    name      = "node-config"
    namespace = "kube-system"
  }

  data = {
    tolerations = jsonencode([
      {
        key      = "blockchain-workload"
        operator = "Equal"
        value    = "true"
        effect   = "NoSchedule"
      }
    ])
  }

  depends_on = [aws_eks_cluster.main]
}
