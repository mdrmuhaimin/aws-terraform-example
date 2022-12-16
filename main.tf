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
  region = var.aws_region

  default_tags {
    tags = {
      project    = "aws-demo"
      maintainer = "terraform"
    }
  }
}

### Add VPC VPC
resource "aws_vpc" "main" {
  # Ref for subnet 
  # https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html  
  # Range 10.0.0.0 - 10.0.255.255
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

