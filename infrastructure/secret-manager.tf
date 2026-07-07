resource "aws_secretsmanager_secret_version" "mlflow_db" {
  secret_id = aws_secretsmanager_secret.mlflow_db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.mlflow_db.result
    engine   = "postgres"
    host     = aws_db_instance.mlflow.address
    port     = "5432"
    dbname   = var.db_name
  })
}