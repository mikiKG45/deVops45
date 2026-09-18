variable "role_name" {
  description = "Name of the IAM role to create."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (from the eks module)."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL (from the eks module), e.g. https://oidc.eks.../id/XXX"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the ServiceAccount that may assume this role."
  type        = string
}

variable "service_account_name" {
  description = "Name of the Kubernetes ServiceAccount that may assume this role."
  type        = string
}

variable "policy_json" {
  description = "Inline IAM policy (JSON) granting this role's permissions. Optional."
  type        = string
  default     = null
}

variable "policy_arns" {
  description = "Managed IAM policy ARNs to attach. Optional."
  type        = list(string)
  default     = []
}
