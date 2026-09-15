# --- Inputs to the network module ---
# The caller (environments/dev) supplies these. Defaults are sensible for a
# small dev VPC, but everything is overridable.

variable "name" {
  description = "Name prefix applied to resource Name tags, e.g. \"devops45-dev\"."
  type        = string
  default     = "devops45-dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. /16 gives ~65k addresses, plenty for pods (VPC CNI assigns each pod a real VPC IP)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones to spread subnets across. Two is enough for dev; the caller passes real AZ names for the region."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "If true, create a NAT gateway so private subnets can reach the internet. We default to false (nodes run in public subnets) to save cost; flip to true for a production-realistic topology."
  type        = bool
  default     = false
}
