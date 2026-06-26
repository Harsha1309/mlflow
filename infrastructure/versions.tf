terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend.
  # Fill in `bucket` and `dynamodb_table` with the values output by
  # backend-bootstrap/main.tf (run that config first, then `terraform init`
  # here to migrate local state to S3).
  backend "s3" {
    bucket         = "eks-sandbox-tfstate-bc175f93" # from backend-bootstrap output: state_bucket_name
    key            = "eks-sandbox/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "eks-sandbox-tf-locks" # from backend-bootstrap output: lock_table_name
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
