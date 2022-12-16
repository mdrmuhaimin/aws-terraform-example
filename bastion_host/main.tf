terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
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

provider "tls" {
  # Configuration options
}

### Create a private key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

### Add public key to aws key pair 
resource "aws_key_pair" "bastion-ssh_key" {
  key_name   = "bastion-ssh_key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

### Store private key to S3

resource "aws_s3_object" "bastion_private_key" {
  bucket  = "xmple"
  key     = "terraform/output/ec2_instances/general/bastion-ssh_key.pem"
  content = tls_private_key.ssh_key.private_key_pem
}

#### Create Bastion Host EC2

# Reference AWS VPC
data "aws_vpc" "example-vpc" {
  tags = {
    "Name" : "example-vpc"
  }
}

# Reference AWS Subnets
data "aws_subnets" "vpc_public_subnets" {
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

# Create security group to allow SSH connection at port 22
resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
  vpc_id = data.aws_vpc.example-vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Bastion host instance

resource "aws_instance" "bastion-host" {
  ami                         = "ami-0912f71e06545ad88" # https://aws.amazon.com/amazon-linux-ami/
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.vpc_public_subnets.ids[0]
  security_groups             = [aws_security_group.bastion-sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion-ssh_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.instnc_profile.name
  tags = {
    Name = "bastion-host"
  }
}

### Add instance profile
# Create an Iam Role
resource "aws_iam_role" "ec2_bastion_role" {
  name = "bastion_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Reference the full S3 access policy created during S3 bucket creation

data "aws_iam_policy" "xmple_s3_full_access" {
  name = "example-general_s3_all"
}

# Attach the iam policy to the IAM role

resource "aws_iam_policy_attachment" "s3-read-only" {
  name       = "s3-access-attach"
  roles      = [aws_iam_role.ec2_bastion_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "s3-access-attach" {
  name       = "s3-access-attach"
  roles      = [aws_iam_role.ec2_bastion_role.name]
  policy_arn = data.aws_iam_policy.xmple_s3_full_access.arn
}

# Instance profile with this role
resource "aws_iam_instance_profile" "instnc_profile" {
  name = "bastion_instnc_prfl"
  role = aws_iam_role.ec2_bastion_role.name
}
