# --- Elastic Container Registry ---
# Private Docker registry for the demo app image. Lives in bootstrap (not the
# env layer) so it PERSISTS across environment create/destroy cycles — your
# built images survive when you tear the cluster down between work sessions.

resource "aws_ecr_repository" "demo_app" {
  name = "devops45/demo-app"

  # IMMUTABLE means a tag, once pushed, can never be overwritten. This is a
  # supply-chain safeguard: "demo-app:abc123" always refers to the exact same
  # image. CI will tag images by git commit SHA, so we never need to reuse a tag.
  image_tag_mutability = "IMMUTABLE"

  # Scan each pushed image for known CVEs. Basic scanning is free.
  image_scanning_configuration {
    scan_on_push = true
  }

  # Images are encrypted at rest (Gabe's "encrypted storage" requirement).
  # AES256 is AWS-managed and free; KMS would add per-key cost + management.
  encryption_configuration {
    encryption_type = "AES256"
  }

  # CRITICAL for the destroy path: without this, `terraform destroy` FAILS if the
  # repo still contains images ("repository not empty"). force_delete lets Terraform
  # remove the repo and its images together — exactly the kind of teardown snag
  # Gabe warned about.
  force_delete = true
}

# Lifecycle policy: keep only the 10 most recent images so old builds don't pile
# up (storage cost + clutter). ECR applies this automatically.
resource "aws_ecr_lifecycle_policy" "demo_app" {
  repository = aws_ecr_repository.demo_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
