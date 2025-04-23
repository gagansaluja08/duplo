# dev.tfvars - Development Environment
environment = "dev"
region = "us-west-2"
kubernetes_version = "1.28"
worker_node_min_size = 1
worker_node_max_size = 2
worker_node_desired_size = 1
worker_node_instance_types = ["t3.medium"]
tags = {
 Terraform   = "true"
  Project     = "EKS-Demo"
  Environment = "Development"
}
