terraform {
  required_version = ">= 1.3.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.region
}

# This allows us to retrieve EKS cluster information
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks.cluster_id]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks.cluster_id]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.environment}-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.environment}-cluster" = "shared"
  }

  tags = var.tags
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = "${var.environment}-cluster"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      min_size     = var.worker_node_min_size
      max_size     = var.worker_node_max_size
      desired_size = var.worker_node_desired_size

      instance_types = var.worker_node_instance_types
      capacity_type  = "ON_DEMAND"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Custom user data for required installations
      pre_bootstrap_user_data = <<-EOT
#!/bin/bash
# Install required tools
yum update -y
yum install -y net-tools curl vim bind-utils sysstat tcpdump

# Install all pending security updates
yum update --security -y

# Disable SSH
systemctl disable sshd
systemctl stop sshd

# Enable SELinux in enforcing mode
setenforce 1
sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
EOT
    }
  }

  tags = var.tags
}

# Deploy a simple web application on EKS
resource "kubernetes_deployment" "example" {
  depends_on = [module.eks]
  
  metadata {
    name = "nginx-example"
    labels = {
      app = "nginx-example"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx-example"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-example"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Create Kubernetes service (Load Balancer)
resource "kubernetes_service" "example" {
  depends_on = [kubernetes_deployment.example]
  
  metadata {
    name = "nginx-example"
  }

  spec {
    selector = {
      app = "nginx-example"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# Output the load balancer URL
output "load_balancer_hostname" {
  value = kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname
  description = "The hostname of the load balancer"
}
