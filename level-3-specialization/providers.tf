terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Path is set dynamically via: terraform init -backend-config=env/<env>.backend.hcl
  backend "local" {}
}

provider "aws" {
  region = var.region
}
