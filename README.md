# AWS EKS Terraform Project

This project provisions a complete AWS EKS infrastructure using Terraform, designed to be environment-agnostic and easily deployable multiple times within a single AWS region.

## Project Overview

This Terraform solution creates:
- A custom VPC with public and private subnets
- An EKS cluster
- EC2 instances configured as EKS worker nodes
- A container application with a web interface running on EKS
- A load balancer exposing the web application

## Requirements

### Technical Requirements
- Terraform ≥ 1.3.3
- AWS Account with appropriate permissions
- AWS CLI installed and configured
- kubectl (for interacting with the cluster post-deployment)

### EC2 Worker Node Configuration
Worker nodes are automatically configured on first boot to:
- Install required tools:
  - Netstat
  - Curl
  - Vim
  - Dig
  - Vmstat
  - Tcpdump
- Install all pending security updates
- Turn off SSH daemon (sshd)
- Enable SELinux in enforcing mode

## Project Structure

```
.
├── README.md                # This file
├── main.tf                  # Main Terraform configuration
├── variables.tf             # Variable definitions
├── dev.tfvars               # Development environment variables
├── prod.tfvars              # Production environment variables (sample)
```

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aws-eks-terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Deploy an environment**
   ```bash
   terraform apply -var-file=dev.tfvars
   ```

4. **Access the deployed application**
   After deployment completes, the load balancer URL will be displayed in the outputs. You can use this URL to access the web application.

## Environment Management

This project supports multiple environments within the same AWS region. Each environment gets its own:
- VPC
- EKS Cluster
- Worker nodes
- Application deployment

### Creating Multiple Environments

1. **Create environment-specific variable files**
   
   Duplicate the `dev.tfvars` file and modify parameters as needed:
   ```bash
   cp dev.tfvars staging.tfvars
   # Edit staging.tfvars to set environment = "staging"
   ```

2. **Deploy the new environment**
   ```bash
   terraform apply -var-file=staging.tfvars
   ```

### Environment Isolation

Each environment is completely isolated from others with:
- Separate networking (VPC)
- Separate compute resources (EKS cluster and worker nodes)
- Unique resource names based on environment variable

## Customization

### Worker Node Sizing
Adjust the following variables in your `.tfvars` file to control worker node scaling:
- `worker_node_min_size`
- `worker_node_max_size`
- `worker_node_desired_size`
- `worker_node_instance_types`

### Network Configuration
Network settings can be customized through:
- `vpc_cidr`
- `private_subnets`
- `public_subnets`

## Cleanup

To remove all resources created by Terraform:

```bash
terraform destroy -var-file=dev.tfvars
```

Repeat for each environment you've deployed.

## For Developers

### Connecting to the Kubernetes Cluster

After deployment, configure kubectl to connect to your new cluster:

```bash
aws eks update-kubeconfig --region <your-region> --name <environment>-cluster
```

Example:
```bash
aws eks update-kubeconfig --region us-west-2 --name dev-cluster
```

### Basic Kubernetes Commands

```bash
# List nodes in the cluster
kubectl get nodes

# View running pods
kubectl get pods

# Check services and load balancer
kubectl get services

# View deployment details
kubectl describe deployment nginx-example
```

## Security Notes

- SSH access to worker nodes is disabled by default
- SELinux is configured in enforcing mode
- Security updates are automatically applied during instance initialization
- The VPC is configured with proper security best practices

## Troubleshooting

For detailed troubleshooting guidance, refer to the [Deployment Guide](./docs/deployment-guide.md).

Common issues:
1. **Insufficient IAM permissions**: Ensure your AWS user has appropriate permissions
2. **Resource limits**: AWS accounts have default limits that may need to be increased
3. **Network connectivity**: Check your VPC configuration if networking issues occur

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
