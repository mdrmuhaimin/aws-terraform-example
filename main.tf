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

### Add VPC
resource "aws_vpc" "main" {
  # Ref for subnet 
  # https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html  
  # Range 10.0.0.0 - 10.0.255.255
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

### Create subnets

# Get available azs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create private and public subnets in the first two available availability zones
resource "aws_subnet" "primary_public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24" #10.0.0.0 - 10.0.0.255
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "secondary_public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24" #10.0.1.0 - 10.0.1.255
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-b"
  }
}

resource "aws_subnet" "private_primary" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.16.0/20" # 10.0.16.0 - 10.0.31.255
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "private-a"
  }
}

resource "aws_subnet" "private_secondary" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/20" # 10.0.32.0 - 10.0.47.255
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "private-b"
  }
}

### Create Internet Gateway

resource "aws_internet_gateway" "igw-this" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-main"
  }
}

### Create Route Table
resource "aws_route_table" "route-table-this" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-this.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw-this.id
  }

  tags = {
    Name = "rt-main"
  }
}

### Route table subnet assoication 

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.primary_public.id
  route_table_id = aws_route_table.route-table-this.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.secondary_public.id
  route_table_id = aws_route_table.route-table-this.id
}
