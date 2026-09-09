# Configures the AWS provider: which region to act in, and which local
# credentials to use. `profile` points at the `devops45` entry in your
# ~/.aws/credentials, so no keys are ever written into this repo.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Tags automatically stamped onto every taggable resource this layer creates.
  # Makes cost tracking and "what is this / can I delete it" trivial later.
  default_tags {
    tags = {
      Project   = "deVops45"
      ManagedBy = "Terraform"
      Layer     = "bootstrap"
    }
  }
}
