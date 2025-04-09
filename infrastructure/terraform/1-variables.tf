locals {
    region = "ap-southeast-2"
    availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    vpc_name = "ecommerce-web-gen-vpc"

    igw_name = "ecommerce-web-gen-igw"
    default_route = "0.0.0.0/0"

    public_subnet_name_prefix = "public-ecommerce-web-gen-subnet"
    public_subnet_route_table_name = "public-ecommerce-web-gen-subnet-route-table"

    private_subnet_name_prefix = "private-ecommerce-web-gen-subnet"
    private_subnet_route_table_name = "private-ecommerce-web-gen-subnet-route-table"

    eks_cluster_name = "ecommerce-web-gen-eks-cluster"
    eks_kubernetes_version = "1.31"
    eks_cluster_service_role_name = "ecommerce-web-gen-eks-cluster-service-role"

    ecommerce-web-gen-namespace = "ecommerce-web-gen"

    fargate_pod_execution_role_name = "ecommerce-web-gen-eks-cluster-fargate-pod-execution-role"
    fargate_profile_name = "ecommerce-web-gen-eks-cluster-fargate-profile"
}

variable "vpc_cidr" {
    description = "CIDR block for the web gen VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for the public web gen subnets"
  type = list(string)
  default = ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
}

variable "private_subnets" {
  description = "CIDR blocks for the private web gen subnets"
  type = list(string)
  default = ["10.0.12.0/22", "10.0.16.0/22", "10.0.20.0/22"]
}