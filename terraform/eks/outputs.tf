output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.blockchain.id
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS nodes"
  value       = aws_iam_role.node.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "nat_gateway_ips" {
  description = "List of NAT gateway public IPs"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "cluster_info" {
  description = "Cluster information summary"
  value = {
    name               = aws_eks_cluster.main.name
    version            = aws_eks_cluster.main.version
    endpoint           = aws_eks_cluster.main.endpoint
    region             = var.aws_region
    node_instance_type = var.node_instance_types[0]
    node_count         = var.node_desired_size
    vpc_cidr           = var.vpc_cidr
    environment        = var.environment
  }
}
