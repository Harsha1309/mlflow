resource "kubernetes_namespace" "mlflow" {
  metadata {
    name = var.mlflow_namespace
  }
}

resource "kubernetes_service_account" "mlflow" {
  metadata {
    name      = var.mlflow_service_account_name
    namespace = kubernetes_namespace.mlflow.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.mlflow_irsa.arn
    }
  }

  depends_on = [kubernetes_namespace.mlflow]
}

resource "kubernetes_service_account" "dvc_runner" {
  metadata {
    name      = var.dvc_service_account_name
    namespace = kubernetes_namespace.mlflow.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.dvc_irsa_role.iam_role_arn
    }
  }

  depends_on = [kubernetes_namespace.mlflow]
}
