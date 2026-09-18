output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint (used by kubectl / providers)."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 CA cert for authenticating to the API."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider (IRSA roles trust this)."
  value       = aws_iam_openid_connect_provider.oidc.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL (without https://) used in IRSA trust policies."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_role_arn" {
  description = "IAM role ARN of the worker nodes."
  value       = aws_iam_role.node.arn
}

output "cluster_security_group_id" {
  description = "The cluster security group EKS creates; nodes/pods use it. RDS allows only this."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

