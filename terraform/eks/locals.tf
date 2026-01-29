# Local values for resource naming and configuration
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  # Networking
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),  # 10.0.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),  # 10.0.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3),  # 10.0.3.0/24
  ]
  
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 101),  # 10.0.101.0/24
    cidrsubnet(var.vpc_cidr, 8, 102),  # 10.0.102.0/24
    cidrsubnet(var.vpc_cidr, 8, 103),  # 10.0.103.0/24
  ]
  
  # Tags
  default_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Cluster     = local.cluster_name
    }
  )
}
