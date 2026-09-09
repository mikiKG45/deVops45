# --- Remote state backend configuration ---
# Tells Terraform to store THIS layer's state in the S3 bucket that state.tf
# created moments ago. Adding this block and re-running
# `terraform init -migrate-state` moves the local terraform.tfstate into S3.
#
# NOTE: a backend block cannot use variables or interpolation — Terraform reads
# it before anything else is evaluated — so every value here is a literal.
terraform {
  backend "s3" {
    bucket = "devops45-tfstate-705959604116"

    # Each layer gets its own key so their states never collide. The env layer
    # will use "environments/dev/terraform.tfstate", etc.
    key = "bootstrap/terraform.tfstate"

    region = "eu-central-1"

    # The backend does NOT inherit the provider's profile — it resolves its own
    # credentials separately — so it must be told which profile to use.
    profile = "devops45"

    use_lockfile = true # S3-native state locking (replaces the old DynamoDB table)
    encrypt      = true # encrypt the state object in S3
  }
}
