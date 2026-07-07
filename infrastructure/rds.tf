data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "random_password" "mlflow_db" {
  length           = 24
  special          = true
  override_special = "!#%^*()-_=+"
}

resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Allow PostgreSQL traffic from the EKS node group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL from the EKS VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "mlflow" {
  name       = "${var.cluster_name}-mlflow-db-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "${var.cluster_name}-mlflow-db-subnet-group"
  }
}

resource "aws_secretsmanager_secret" "mlflow_db" {
  name = "${var.cluster_name}/mlflow/db"
}


resource "aws_db_instance" "mlflow" {
  identifier                   = "${var.cluster_name}-mlflow"
  engine                       = "postgres"
  engine_version               = "16.14"
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_storage_gb
  storage_type                 = "gp2"
  db_name                      = var.db_name
  username                     = var.db_username
  password                     = random_password.mlflow_db.result
  parameter_group_name         = null
  skip_final_snapshot          = true
  publicly_accessible          = false
  vpc_security_group_ids       = [aws_security_group.rds.id]
  db_subnet_group_name         = aws_db_subnet_group.mlflow.name
  backup_retention_period      = 7
  deletion_protection          = false
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  backup_window                = "03:00-04:00"
  maintenance_window           = "sun:04:00-sun:05:00"
  performance_insights_enabled = false
  tags = {
    Name = "${var.cluster_name}-mlflow-db"
  }
}

