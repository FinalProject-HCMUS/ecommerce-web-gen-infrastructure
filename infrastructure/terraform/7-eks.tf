# IAM Role for the EKS control plane to perform actions on your behalf
resource "aws_iam_role" "eks_cluster_service_role" {
  name = local.eks_cluster_service_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = local.eks_cluster_service_role_name
  }
}

# Attach required policies to cluster service role
resource "aws_iam_role_policy_attachment" "eks_cluster_service_role_policy_1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_service_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_service_role_policy_2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_service_role.name
}

# Create the EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_service_role.arn
  version  = local.eks_kubernetes_version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = [local.default_route]
  }

  tags = {
    Name = local.eks_cluster_name
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.eks_cluster_service_role_policy_1,
    aws_iam_role_policy_attachment.eks_cluster_service_role_policy_2
  ]
}