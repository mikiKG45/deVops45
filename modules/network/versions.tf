# A module declares which providers it needs, but NOT a provider block — the
# provider (region, credentials) is inherited from whoever calls the module
# (here: environments/dev). This keeps the module reusable across accounts/regions.
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
