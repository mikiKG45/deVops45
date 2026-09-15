# --- Outputs: what this module hands back to its caller ---
# The EKS and RDS modules will consume these (which VPC, which subnets).
# AWS assigns these IDs at apply time, so they can't be known in advance.

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC (handy for security group rules later)."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (EKS nodes, internet-facing load balancers)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (RDS lives here)."
  value       = aws_subnet.private[*].id
}
