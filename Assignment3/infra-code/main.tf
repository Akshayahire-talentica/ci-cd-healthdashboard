terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  tags = merge(
    var.default_tags,
    {
      Project = var.project_name
      Managed = "terraform"
    }
  )
}

module "vpc" {
  source                 = "./modules/vpc"
  project_name           = var.project_name
  cidr_block             = var.vpc_cidr
  public_subnet_cidr     = var.public_subnet_cidr
  az                     = var.az
  enable_dns_hostnames   = true
  enable_dns_support     = true
  tags                   = local.tags
}

module "security_group" {
  source        = "./modules/security_group"
  project_name  = var.project_name
  vpc_id        = module.vpc.vpc_id
  allow_ssh     = var.allow_ssh
  ssh_cidr      = var.ssh_cidr
  tags          = local.tags
  app_ports     = [3001, 8080]
}

module "ec2" {
  source               = "./modules/ec2"
  project_name         = var.project_name
  subnet_id            = module.vpc.public_subnet_id
  vpc_security_group_ids = [module.security_group.sg_id]
  instance_type        = var.instance_type
  key_name             = var.key_name
  tags                 = local.tags
  ami_id               = var.ami_id
}
