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

### Create S3 bucket

resource "aws_s3_bucket" "example-general" {
  force_destroy = true # Dangerous dont add it in prod bucket
  bucket        = var.example_bucket_name
}

resource "aws_s3_bucket_public_access_block" "privatize_example-general" {
  bucket = aws_s3_bucket.example-general.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_example-general" {
  bucket = aws_s3_bucket.example-general.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse_example-general" {
  bucket = aws_s3_bucket.example-general.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_policy" "iam_policy_s3_access" {
  name        = "example-general_s3_all"
  path        = "/"
  description = "Full access to example-general S3 bucket"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
        ],
        "Resource" : [
          "${aws_s3_bucket.example-general.arn}/*"
        ]
      }
    ]
  })
}

