# prod.tfvars - Production Environment
environment = "prod"
region = "us-west-2"
kubernetes_version = "1.28"
worker_node_min_size = 2
worker_node_max_size = 5
worker_node_desired_size = 3
worker_node_instance_types = ["t3.large"]
tags = {
 Terraform   = "true"
  Project     = "EKS-Demo"
  Environment = "Production"
}
