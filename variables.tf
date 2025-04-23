# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "worker_node_min_size" {
  description = "Minimum size of worker node group"
  type        = number
  default     = 1
}

variable "worker_node_max_size" {
  description = "Maximum size of worker node group"
  type        = number
  default     = 3
}

variable "worker_node_desired_size" {
  description = "Desired size of worker node group"
  type        = number
  default     = 2
}

variable "worker_node_instance_types" {
  description = "List of instance types for the worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Project     = "EKS-Demo"
  }
}
