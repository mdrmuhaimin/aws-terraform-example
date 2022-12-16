# Define terraform version, with necessary provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# Define AWS specific configurations
provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      project    = "aws-demo"
      maintainer = "terraform"
    }
  }
}
