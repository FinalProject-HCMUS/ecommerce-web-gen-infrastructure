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

# Create the application namespace
resource "kubernetes_namespace" "ecommerce-web-gen-namespace" {
  metadata {
    name = local.ecommerce-web-gen-namespace
  }
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_lb_controller_role" {
  name = "${local.eks_cluster_name}-lb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::127214192487:oidc-provider/${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.eks_cluster_name}-lb-controller-role"
  }
}

# IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name        = "${local.eks_cluster_name}-lb-controller-policy"
  description = "Policy for AWS Load Balancer Controller to manage ALBs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeVpcs",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:*",
          "iam:CreateServiceLinkedRole",
          "iam:GetServerCertificate",
          "iam:ListServerCertificates",
          "waf-regional:*",
          "wafv2:*",
          "shield:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to the AWS Load Balancer Controller role
resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy_attachment" {
  policy_arn = aws_iam_policy.aws_lb_controller_policy.arn
  role       = aws_iam_role.aws_lb_controller_role.name
}

# AWS Load Balancer Controller Helm release
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.12.0"  # Pinned to a stable version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = local.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller_role.arn
  }

  set {
    name = "region"
    value = local.region
  }

  set {
    name = "vpcId"
    value = aws_vpc.ecommerce-web-gen-vpc.id
  }

  depends_on = [
    aws_vpc.ecommerce-web-gen-vpc,
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.aws_lb_controller_policy_attachment,
    aws_eks_fargate_profile.kube_system
  ]
}

# Helm release for ecommerce-web-gen-chart from OCI-based registry, Docker Hub
resource "helm_release" "ecommerce_web_gen" {
  name       = "ecommerce-web-gen"
  repository = "oci://registry-1.docker.io/21120414"
  chart      = "ecommerce-web-gen-chart"
  version    = "0.1.0"  # Pinned to a stable version 
  namespace  = local.ecommerce-web-gen-namespace

  depends_on = [ 
    aws_eks_cluster.eks_cluster,
    helm_release.aws_lb_controller
  ]
}

# Ingress with ALB (Dynamic IPs)
resource "kubernetes_ingress_v1" "ecommerce_ingress" {
  metadata {
    name      = "ecommerce-ingress"
    namespace = local.ecommerce-web-gen-namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "routing.http2.enabled=true"
      "alb.ingress.kubernetes.io/subnets"         = join(",", aws_subnet.public[*].id)
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "web-ui-service"  # Updated to match your Helm chart service name
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/api/code"
          path_type = "Prefix"
          backend {
            service {
              name = "code-gen-service"  # Updated to match your Helm chart service name
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/api/preview"
          path_type = "Prefix"
          backend {
            service {
              name = "preview-service"  # Updated to match your Helm chart service name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ecommerce_web_gen, helm_release.aws_lb_controller]
}

# Output the ALB DNS name (no static IPs)
output "alb_dns_name" {
  value = "kubectl get ingress -n ${local.ecommerce-web-gen-namespace} ecommerce-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}