output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  value = aws_eks_cluster.main.version
}

output "configure_kubectl" {
  description = "Run this command to update your local kubeconfig."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "node_group_status" {
  value = aws_eks_node_group.main.status
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint for MLflow."
  value       = aws_db_instance.mlflow.address
}

output "mlflow_secret_arn" {
  description = "Secrets Manager secret ARN containing the RDS password."
  value       = aws_secretsmanager_secret.mlflow_db.arn
}

output "mlflow_irsa_role_arn" {
  description = "IAM role ARN for MLflow IRSA."
  value       = aws_iam_role.mlflow_irsa.arn
}
