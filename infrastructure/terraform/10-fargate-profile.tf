# Fargate Pod Execution Role
resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name = local.fargate_pod_execution_role_name

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    Name = local.fargate_pod_execution_role_name
  }
}

# Attach required policy to Fargate pod execution role
resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_pod_execution_role.name

  depends_on = [aws_iam_role.eks_fargate_pod_execution_role]
}

# Fargate Profile for ecommerce-web-gen namespace
resource "aws_eks_fargate_profile" "ecommerce_web_gen" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = local.fargate_profile_name
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "default"
  }

  selector {
    namespace = local.ecommerce-web-gen-namespace  # Selector for ecommerce-web-gen
  }

  tags = {
    Name = local.fargate_profile_name
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.eks_fargate_pod_execution
  ]
}

# Fargate Profile for kube-system namespace (CoreDNS and AWS Load Balancer Controller)
resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "${local.eks_cluster_name}-kube-system"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = aws_subnet.private[*].id

  selector {
    namespace = "kube-system"  # Covers all kube-system pods, including CoreDNS and AWS LB Controller
  }

  tags = {
    Name = "${local.eks_cluster_name}-kube-system"
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.eks_fargate_pod_execution
  ]
}

# CoreDNS Add-On
resource "aws_eks_addon" "coredns" {
  cluster_name   = aws_eks_cluster.eks_cluster.name
  addon_name     = "coredns"
  addon_version  = "v1.11.4-eksbuild.2"  # Compatible with Kubernetes 1.30

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_fargate_profile.kube_system  # Depends on kube-system profile
  ]
}

# VPC CNI Add-On
resource "aws_eks_addon" "vpc_cni" {
  cluster_name   = aws_eks_cluster.eks_cluster.name
  addon_name     = "vpc-cni"
  addon_version  = "v1.19.3-eksbuild.1"  # Compatible with Kubernetes 1.30

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_fargate_profile.kube_system  # Depends on kube-system profile
  ]
}