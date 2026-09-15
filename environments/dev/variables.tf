variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile used to authenticate."
  type        = string
  default     = "devops45"
}

variable "name" {
  description = "Name prefix for resources in this environment."
  type        = string
  default     = "devops45-dev"
}

variable "azs" {
  description = "Availability Zones to spread subnets across (Frankfurt has 3; we use 2)."
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}
