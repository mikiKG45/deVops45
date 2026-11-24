# Values other layers or you (the human) need after bootstrap runs.
# `terraform output <name>` prints these; other layers can read them from the
# bootstrap state in S3 via a terraform_remote_state data source later.

output "state_bucket_name" {
  description = "S3 bucket holding Terraform state for all layers."
  value       = aws_s3_bucket.tf_state.id
}

output "ecr_repository_url" {
  description = "Full URL to docker push/pull the demo app image."
  value       = aws_ecr_repository.demo_app.repository_url
}

output "github_ci_role_arn" {
  description = "IAM role GitHub Actions assumes via OIDC (goes into the workflow's role-to-assume)."
  value       = aws_iam_role.github_ci.arn
}

