terraform {
  backend "s3" {
    bucket = "devops45-tfstate-705959604116"

    # Different key from bootstrap so the two states never collide.
    key = "environments/dev/terraform.tfstate"

    region       = "eu-central-1"
    profile      = "devops45"
    use_lockfile = true
    encrypt      = true
  }
}
