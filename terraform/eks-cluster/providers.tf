terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
  
  backend "s3" {
    bucket = "tf-github-actions-aws-eks-cluster"
    key    = "eks-cluster"
    region = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
