output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_secret_arn" {
  value = module.database.db_secret_arn
}

output "app_role_arn" {
  value = module.app_irsa.role_arn
}

output "lb_controller_role_arn" {
  value = module.lb_controller_irsa.role_arn
}
