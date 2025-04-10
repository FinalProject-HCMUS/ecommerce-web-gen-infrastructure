# Fetch current AWS account ID
data "aws_caller_identity" "current" {}

# Define OIDC provider explicitly (only if not already associated with the cluster)
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9E99A48A9960B14926BB7F3B02E22DA2B0AB7280"] # Default thumbprint, verify if still valid
}

# IAM policy document for AWS Load Balancer Controller
data "http" "iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# IAM policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.iam_policy.response_body
}

# IAM role trust relationship policy for the service account
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.namespace}:${local.service_account_name}"]
    }
  }
}

# IAM role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_lb_controller_role" {
  name               = "AWSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Attach IAM policy to the role
resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy_attachment" {
  role       = aws_iam_role.aws_lb_controller_role.name
  policy_arn = aws_iam_policy.aws_lb_controller_policy.arn
}

# Helm release for AWS Load Balancer Controller
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.12.0" # Pinned version, update as needed
  namespace  = local.namespace

  # Configuration values
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
    value = local.service_account_name
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller_role.arn
  }
  set {
    name  = "region"
    value = local.region
  }
  set {
    name  = "vpcId"
    value = aws_vpc.ecommerce-web-gen-vpc.id
  }

  depends_on = [
    aws_vpc.ecommerce-web-gen-vpc,                  # Assumed resource
    aws_eks_cluster.eks_cluster,                    # Assumed resource
    aws_iam_role_policy_attachment.aws_lb_controller_policy_attachment,
    aws_eks_fargate_profile.kube_system             # Assumed resource
  ]
}

# Kubernetes Ingress for ALB (Dynamic IPs)
resource "kubernetes_ingress_v1" "ecommerce_ingress" {
  metadata {
    name      = "ecommerce-ingress"
    namespace = local.ecommerce-web-gen-namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "routing.http2.enabled=true"
      "alb.ingress.kubernetes.io/subnets"         = join(",", aws_subnet.public[*].id) # Assumes subnets defined
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
              name = "web-ui-service"
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
              name = "code-gen-service"
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
              name = "preview-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_lb_controller,
    helm_release.ecommerce_web_gen # Assumed resource
  ]
}

# Output ALB DNS name
output "alb_dns_name" {
  description = "Command to fetch the ALB DNS name after deployment"
  value       = "kubectl get ingress -n ${local.ecommerce-web-gen-namespace} ecommerce-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}