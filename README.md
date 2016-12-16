# Terraform module: AWS VPC

Creates a VPC with private and public subnets in each availability zone for the specified region.  Also starts a NAT Gateway to allow outside communication from private subnets.

Required variables are `vpc_name`, `vpc_region`, and `availability_zones`.
