module "vpc" {
  source                     = "../modules/vpc"
  cidr_block                 = var.vpc_cidr
  account_name               = var.account_name
  cluster_name               = [
    "alchemy",
  ]
  application_name           = "app"
  eks_enabled                = true
}

