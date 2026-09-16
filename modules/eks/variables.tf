variable "name" {
  description = "Name prefix, e.g. \"devops45-dev\"."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.32"
}

variable "subnet_ids" {
  description = "Subnets for the EKS control plane ENIs (public + private, spanning 2 AZs)."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnets where worker nodes run. We use the PUBLIC subnets (no NAT)."
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the node group. t3.medium gives enough pod capacity for Argo CD + app."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}
