# --- KMS key for RDS storage encryption ---
resource "aws_kms_key" "db" {
  description             = "KMS key for RDS storage encryption (${var.name})"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.name}-db-kms"
  }
}

resource "aws_kms_alias" "db" {
  name          = "alias/${var.name}-db"
  target_key_id = aws_kms_key.db.key_id
}

# --- Randomly generated database password ---
# Never typed by hand, never committed. Generated once, then stored in Secrets Manager.
resource "random_password" "db" {
  length  = 24
  special = true
  # Restrict special chars to ones safe inside connection strings / URIs
  # (avoids /, @, quotes, etc. that would break a postgres:// URL).
  override_special = "!#$%*()-_=+[]{}"
}

# --- Secrets Manager: the vault entry (container) ---
# The actual value (with host/port) is written in part 4a-4, once RDS exists.
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.name}/db-credentials"
  description = "Credentials for the ${var.name} PostgreSQL database"
  kms_key_id  = aws_kms_key.db.arn

  # 0 = a deleted secret is removed immediately (no 7-30 day recovery window).
  # Important for our destroy/recreate cycle so the name isn't "stuck deleting".
  recovery_window_in_days = 0
}
