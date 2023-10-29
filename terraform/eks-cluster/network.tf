locals{
  cidr = var.vpc.cidr
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = "eks-${var.env}"
  cidr = local.cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k + 48)]

  private_subnet_tags = {
    Tier = "private"
  }

  public_subnet_tags = {
    Tier = "public"
  }

  enable_nat_gateway = true
  single_nat_gateway  = true # Force single natgateway
  one_nat_gateway_per_az = false # Force single natgateway


  enable_dns_hostnames = true
  enable_vpn_gateway = false

  tags = var.tags
}