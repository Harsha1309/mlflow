# --- EKS cluster (control plane) role ---

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- Worker node role ---

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "mlflow_irsa" {
  name = "${var.cluster_name}-mlflow-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:${var.mlflow_namespace}:${var.mlflow_service_account_name}"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

data "aws_iam_policy_document" "mlflow_artifact_s3_access" {
  statement {
    sid    = "AllowListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [aws_s3_bucket.dvc_store.arn]
  }

  statement {
    sid    = "AllowObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.dvc_store.arn}/*"]
  }
}

resource "aws_iam_policy" "mlflow_artifact_s3_access" {
  name        = "${var.cluster_name}-mlflow-artifact-s3-access"
  description = "Allow MLflow server to use the DVC S3 bucket for artifact storage"
  policy      = data.aws_iam_policy_document.mlflow_artifact_s3_access.json
}

resource "aws_iam_role_policy_attachment" "mlflow_artifact_s3_access" {
  role       = aws_iam_role.mlflow_irsa.name
  policy_arn = aws_iam_policy.mlflow_artifact_s3_access.arn
}

resource "aws_iam_policy" "mlflow_secret_read" {
  name = "${var.cluster_name}-mlflow-secret-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [aws_secretsmanager_secret.mlflow_db.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "mlflow_secret_read" {
  role       = aws_iam_role.mlflow_irsa.name
  policy_arn = aws_iam_policy.mlflow_secret_read.arn
}




data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "dvc_store" {
  # Account ID suffix keeps this globally unique without you having to
  # hand-pick a name — S3 bucket names are unique across ALL AWS accounts,
  # not just yours.
  bucket = "${var.cluster_name}-${var.dvc_bucket_suffix}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "${var.cluster_name}-${var.dvc_bucket_suffix}"
    ManagedBy = "terraform"
    Purpose   = "dvc-remote-storage"
  }
}

resource "aws_s3_bucket_versioning" "dvc_store" {
  bucket = aws_s3_bucket.dvc_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dvc_store" {
  bucket = aws_s3_bucket.dvc_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "dvc_store" {
  bucket = aws_s3_bucket.dvc_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: DVC keeps every historical blob by content hash, so without
# this the bucket only grows. Kept short here since this is a sandbox —
# tighten/loosen the day counts to taste.
resource "aws_s3_bucket_lifecycle_configuration" "dvc_store" {
  bucket = aws_s3_bucket.dvc_store.id

  rule {
    id     = "transition-and-expire-noncurrent"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "dvc_store_tls_only" {
  bucket = aws_s3_bucket.dvc_store.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.dvc_store.arn,
          "${aws_s3_bucket.dvc_store.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
