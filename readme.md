# Infrastructure as Code (IaC) using Terraform in AWS

## A hands on workshop

Terraform code for workshop Infrastructure as Code (IaC) using Terraform in AWS

The associated slides can be found [here](https://docs.google.com/presentation/d/1WYNnbowP_w24A4-JqIvNmKtMAkB_g4wR6664BPM8HdU/edit?usp=sharing)

## How to follow the tutorial

- Install terraform
- Configure AWS CLI
- Go through each commit and apply the terraform configurations
- When provisioning the resource use the following order
  - [vpc](vpc/main.tf)
  - [s3](s3/main.tf)
  - [bastion_host](bastion_host/main.tf)
- When deprovisioning use the order in reverse
