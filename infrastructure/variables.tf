variable "aws_region" {
  description = "AWS region. Pluralsight sandbox only allows us-east-1 or us-west-2."
  type        = string
  default     = "us-west-2"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
    error_message = "Sandbox only permits us-east-1 or us-west-2."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "sandbox-eks"
}

variable "cluster_version" {
  description = "Kubernetes version. Must be a version in EKS standard support (not extended) per sandbox rules."
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the sandbox VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across (2 is enough for EKS HA requirements)."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group. Sandbox only allows t2/t3/t3a/t4g in micro/small/medium sizes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes. Kept low — sandbox caps total concurrent EC2 instances at 9."
  type        = number
  default     = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  description = "EBS volume size (GB) per worker node. Sandbox caps EC2 volumes at 100GB."
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class for the MLflow PostgreSQL database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_storage_gb" {
  description = "RDS storage size in GB for the MLflow PostgreSQL database."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name for the MLflow PostgreSQL instance."
  type        = string
  default     = "mlflow"
}

variable "db_username" {
  description = "Master username for the MLflow PostgreSQL instance."
  type        = string
  default     = "mlflow"
}

variable "mlflow_namespace" {
  description = "Namespace for the MLflow deployment."
  type        = string
  default     = "mlflow"
}

variable "mlflow_service_account_name" {
  description = "Service account name used by MLflow pods for IRSA."
  type        = string
  default     = "mlflow"
}

variable "project_name" {
  description = "Short project name used in resource naming, e.g. 'mlflow'"
  type        = string
  default     = "mlflow"
}

variable "environment" {
  description = "Environment name, e.g. 'dev' or 'prod'"
  type        = string
  default     = "dev"
}

variable "dvc_bucket_suffix" {
  description = "Suffix appended to cluster_name to form the DVC remote storage bucket name (must be globally unique across AWS)."
  type        = string
  default     = "dvc-store"
}

variable "dvc_service_account_name" {
  description = "Service account name used by DVC runners (CI jobs / training pods) for IRSA, mirroring mlflow_service_account_name."
  type        = string
  default     = "dvc-runner"
}
