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

module "database" {
  source = "../../modules/database"

  name               = var.name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # Only the EKS cluster's security group may reach the database.
  allowed_security_group_id = module.eks.cluster_security_group_id
}

# IRSA role the demo app (Phase 5) will use to read its DB credentials.
module "app_irsa" {
  source = "../../modules/irsa-role"

  role_name         = "${var.name}-demo-app"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  namespace            = "demo"
  service_account_name = "demo-app"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [module.database.db_secret_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [module.database.db_kms_key_arn]
      }
    ]
  })
}
