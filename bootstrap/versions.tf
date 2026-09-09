# Pins the Terraform CLI and provider versions this layer is known to work with.
# Pinning matters: it means you, your teammate, and CI all resolve the SAME
# AWS provider, so a plan never differs just because someone had a newer version.
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # any 5.x release, but never an automatic jump to 6.x
    }
  }
}
