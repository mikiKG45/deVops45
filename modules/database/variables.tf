variable "name" {
  description = "Name prefix, e.g. \"devops45-dev\"."
  type        = string
}

variable "vpc_id" {
  description = "VPC where the DB security group lives."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group (no internet route)."
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "The ONLY security group allowed to reach the DB (the EKS cluster SG)."
  type        = string
}

variable "db_name" {
  description = "Initial database name created inside the instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "appuser"
}

variable "instance_class" {
  description = "RDS instance size. db.t4g.micro is the cheapest Graviton option."
  type        = string
  default     = "db.t4g.micro"
}

variable "engine_version" {
  description = "PostgreSQL major version. RDS picks the latest compatible minor."
  type        = string
  default     = "16"
}

variable "allocated_storage" {
  description = "Storage in GB. 20 is the minimum for RDS."
  type        = number
  default     = 20
}
