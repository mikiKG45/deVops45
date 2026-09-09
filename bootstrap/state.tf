# --- Remote state backend resources ---
# This bucket holds the Terraform state for every OTHER layer in this repo.
# The bootstrap layer creates it while running on LOCAL state, then migrates
# its own state into the bucket afterwards (terraform init -migrate-state).
# Locking is done by S3 natively (see backend.tf), so there is no lock table.

# Look up the current account ID so the bucket name is globally unique without
# hardcoding the number. S3 bucket names share one global namespace.
data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "devops45-tfstate-${data.aws_caller_identity.current.account_id}"
}

# The bucket that stores state files.
resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket_name
}

# Versioning keeps every prior state file. If an apply corrupts state, you can
# roll back to a known-good version instead of losing your infra's record.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest. State can contain secrets (DB passwords, etc.), so this
# is not optional. AES256 (SSE-S3) is free and needs no key management.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Slam the door on public access. A state bucket should NEVER be reachable from
# the internet. All four flags on.
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# State locking is handled by S3 natively (backend.tf: use_lockfile = true),
# so no separate DynamoDB lock table is needed.
