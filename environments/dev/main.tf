# Calls the reusable network module with this environment's concrete values.
module "network" {
  source = "../../modules/network"

  name = var.name
  azs  = var.azs
  # vpc_cidr and enable_nat_gateway fall back to the module's defaults
  # (10.0.0.0/16 and NAT disabled).
}
