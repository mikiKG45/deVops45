# --- The RDS PostgreSQL instance ---
resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true                # encrypted storage (Gabe's requirement)
  kms_key_id        = aws_kms_key.db.arn

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result    # the random password from secrets.tf

  db_subnet_group_name   = aws_db_subnet_group.this.name  # private subnets
  vpc_security_group_ids = [aws_security_group.db.id]     # "only from cluster" SG

  publicly_accessible = false             # NEVER reachable from the internet

  # Dev-friendly / cost-friendly settings:
  multi_az                = false          # single instance (no standby) — cheaper
  skip_final_snapshot     = true           # don't snapshot on destroy (faster teardown)
  deletion_protection     = false          # allow terraform destroy to delete it
  backup_retention_period = 1              # minimal backups

  tags = {
    Name = "${var.name}-db"
  }
}

# --- Write the FULL credentials (now with host/port) into Secrets Manager ---
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.this.address  # available only after RDS exists
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}



