output "db_endpoint" {
  description = "RDS endpoint hostname (where the app connects)."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port (5432)."
  value       = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB credentials (IRSA policy allows reading this)."
  value       = aws_secretsmanager_secret.db.arn
}

output "db_security_group_id" {
  description = "The DB security group ID."
  value       = aws_security_group.db.id
}

output "db_kms_key_arn" {
  description = "KMS key ARN used for the secret/storage (app needs kms:Decrypt on it)."
  value       = aws_kms_key.db.arn
}
