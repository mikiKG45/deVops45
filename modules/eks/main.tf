# --- The EKS cluster (control plane) ---
resource "aws_eks_cluster" "this" {
  name     = "${var.name}-eks"
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = var.subnet_ids

    # Public endpoint = you can reach the cluster API with kubectl from your laptop.
    # Private endpoint = nodes talk to the API over the VPC internally.
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Who can authenticate + auto-grant admin to whoever creates the cluster (you).
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Envelope-encrypt Kubernetes secrets with our KMS key.
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  # Don't try to create the cluster until its IAM policy is actually attached.
  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = {
    Name = "${var.name}-eks"
  }
}
