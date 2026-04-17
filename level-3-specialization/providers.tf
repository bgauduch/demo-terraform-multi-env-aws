terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
  }

  # Path is set dynamically via: terraform init -backend-config=env/<env>.backend.hcl
  backend "local" {}
}

provider "aws" {
  region = var.region
}
