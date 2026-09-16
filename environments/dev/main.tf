# Calls the reusable network module with this environment's concrete values.
module "network" {
  source = "../../modules/network"

  name = var.name
  azs  = var.azs
  # vpc_cidr and enable_nat_gateway fall back to the module's defaults
  # (10.0.0.0/16 and NAT disabled).
}

module "eks" {
  source = "../../modules/eks"

  name = var.name

  # Control plane spans all subnets (public + private, 2 AZs).
  subnet_ids = concat(
    module.network.public_subnet_ids,
    module.network.private_subnet_ids,
  )

  # Worker nodes run in the public subnets (no NAT).
  node_subnet_ids = module.network.public_subnet_ids
}
