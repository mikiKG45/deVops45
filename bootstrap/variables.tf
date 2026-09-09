# Inputs for the bootstrap layer. Defaults are set so this layer runs with no
# extra config, but keeping them as variables (not hardcoded) means the same
# code could target another region/profile later without edits.

variable "aws_region" {
  description = "AWS region where bootstrap resources live."
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "Local AWS CLI named profile used to authenticate."
  type        = string
  default     = "devops45"
}

variable "alert_email" {
  description = "Email address that receives budget alerts. No default on purpose — you must set it."
  type        = string
}
