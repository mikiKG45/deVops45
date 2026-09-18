output "role_arn" {
  description = "ARN of the created role. Annotate the K8s ServiceAccount with this."
  value       = aws_iam_role.this.arn
}
