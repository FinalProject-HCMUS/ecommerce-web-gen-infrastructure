# Create the application namespace
resource "kubernetes_namespace" "ecommerce-web-gen-namespace" {
  metadata {
    name = local.ecommerce-web-gen-namespace
  }
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
    kubernetes_namespace.ecommerce-web-gen-namespace,
    aws_eks_fargate_profile.ecommerce_web_gen,
    helm_release.aws_lb_controller
  ]
}