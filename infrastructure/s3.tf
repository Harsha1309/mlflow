# Note: S3 bucket resources (aws_s3_bucket, versioning, encryption,
# public_access_block, lifecycle) are defined in iam.tf
#
# Least-privilege IAM policy + IRSA role for DVC access to the bucket.
# Reuses var.mlflow_namespace (same namespace your MLflow
# ServiceAccount already lives in) and the existing EKS module's OIDC
# provider — adjust `module.eks.oidc_provider_arn` below if your EKS
# module/module name differs from the terraform-aws-modules/eks/aws
# convention.

data "aws_iam_policy_document" "dvc_store_access" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.dvc_store.arn]
  }

  statement {
    sid    = "ReadWriteObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.dvc_store.arn}/*"]
  }
}

resource "aws_iam_policy" "dvc_store_access" {
  name        = "${var.cluster_name}-dvc-store-access"
  description = "Least-privilege access to the DVC remote storage bucket"
  policy      = data.aws_iam_policy_document.dvc_store_access.json
}

# IRSA role assumable by the dvc-runner ServiceAccount in the mlflow
# namespace — same pattern as the mlflow_service_account_name IRSA role
# already used for MLflow -> RDS/Secrets Manager access.
module "dvc_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${var.cluster_name}-dvc-irsa"

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["${var.mlflow_namespace}:${var.dvc_service_account_name}"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dvc_irsa_attach" {
  role       = module.dvc_irsa_role.iam_role_name
  policy_arn = aws_iam_policy.dvc_store_access.arn
}
