# --- KMS key for EKS secrets envelope encryption ---
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption (${var.name})"
  deletion_window_in_days = 7    # if destroyed, key waits 7 days before permanent deletion
  enable_key_rotation     = true # AWS rotates the underlying key material yearly

  tags = {
    Name = "${var.name}-eks-kms"
  }
}

# A friendly alias so you see "alias/devops45-dev-eks" instead of a raw key ID.
resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}
