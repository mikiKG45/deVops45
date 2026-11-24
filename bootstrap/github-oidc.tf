# --- GitHub Actions → AWS via OIDC (no long-lived access keys) ---
# Same mechanism as IRSA, different token issuer: GitHub signs a short-lived JWT
# for each workflow run, and STS swaps it for ~1h credentials — but only if the
# token's claims match this role's trust policy. Nothing secret is stored in GitHub.
#
# Lives in bootstrap (not the env layer) because an account can have only ONE
# provider per issuer URL, and CI must keep working while the cluster is destroyed.

locals {
  github_repo = "mikiKG45/deVops45"
}

# Registers GitHub as a trusted identity provider in this AWS account.
# No thumbprint_list: AWS validates GitHub's certificate against its own trusted
# CA library, so a pinned thumbprint is no longer needed (optional since AWS provider 5.x).
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"] # the "aud" claim GitHub puts in the token
}

# --- Trust policy: WHO may assume the role ---
data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Token must be meant for AWS STS.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only workflows running on the main branch of OUR repo. Forks, PRs and other
    # branches get a different "sub" and are rejected.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "devops45-github-ci"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# --- Permissions: WHAT the role may do — push images to OUR ECR repo, nothing else ---
data "aws_iam_policy_document" "github_ecr_push" {
  # Logging in to ECR (docker login) is account-wide; it cannot be scoped to a repo.
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Everything a `docker push` needs, limited to the demo-app repository.
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability", # "do you already have this layer?" (skip re-upload)
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",      # write the manifest + tag
      "ecr:BatchGetImage", # read manifests (push checks existing tags)
    ]
    resources = [aws_ecr_repository.demo_app.arn]
  }
}

resource "aws_iam_role_policy" "github_ecr_push" {
  name   = "ecr-push-demo-app"
  role   = aws_iam_role.github_ci.id
  policy = data.aws_iam_policy_document.github_ecr_push.json
}
