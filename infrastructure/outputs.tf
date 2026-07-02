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

output "traefik_lb_hostname" {
  description = "Traefik LoadBalancer hostname. May be blank right after apply — the ELB DNS name can take 1-2 min to populate; re-run `terraform output traefik_lb_hostname` if empty."
  value       = try(data.kubernetes_service.traefik.status[0].load_balancer[0].ingress[0].hostname, "")
}