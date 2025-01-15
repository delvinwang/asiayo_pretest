# Provider
provider "aws" {
  region = "ap-southeast-1"
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway   = true
  # Enable NAT gateway per zone for HA
  single_nat_gateway   = false
  tags = {
    "Name" = "eks-vpc"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_policy.json
}

data "aws_iam_policy_document" "eks_cluster_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.27"

  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_iam_role_name = aws_iam_role.eks_cluster.name

  node_groups = {
    eks_nodes = {
      desired_capacity = 3
      min_size         = 3
      max_size         = 5

      instance_type = "t3.medium"

      key_name       = var.key_pair_name
      subnets        = module.vpc.public_subnets
    }
  }

  tags = {
    Environment = "production"
  }
}

# Outputs
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "node_group_role_arn" {
  value = module.eks.node_groups["eks_nodes"].iam_role_arn
}
