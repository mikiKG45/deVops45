locals {
  # The condition keys use the issuer URL WITHOUT the https:// prefix.
  oidc_url = replace(var.oidc_provider_url, "https://", "")
}

# --- Trust policy: WHO may assume this role ---
# Only a web-identity token from our OIDC provider, AND only if it belongs to the
# exact namespace:serviceaccount, AND is meant for AWS STS.
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Inline policy (the actual permissions), only if policy_json was given.
resource "aws_iam_role_policy" "inline" {
  count  = var.policy_json == null ? 0 : 1
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

# Any managed policies to attach.
resource "aws_iam_role_policy_attachment" "managed" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

