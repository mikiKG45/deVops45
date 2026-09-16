# --- OIDC provider for IRSA ---
# Registers the cluster's OIDC issuer as an IAM identity provider, so IAM will
# trust tokens the cluster issues to its pods. This is the bridge that lets a
# Kubernetes ServiceAccount assume a scoped IAM role (least privilege).

# Read the issuer's TLS certificate to get its fingerprint (required by IAM).
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}
