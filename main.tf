
module "vpc" {
  source = "./modules/vpc"

  cidr                 = var.vpc["cidr"]
  env                  = var.env
  public_subnets       = var.vpc["public_subnets"]
  web_subnets          = var.vpc["web_subnets"]
  app_subnets          = var.vpc["app_subnets"]
  db_subnets           = var.vpc["db_subnets"]
  availability_zones   = var.vpc["availability_zones"]
  default_vpc_id       = var.vpc["default_vpc_id"]
  default_vpc_rt       = var.vpc["default_vpc_rt"]
  default_vpc_cidr     = var.vpc["default_vpc_cidr"]
}

module "ec2" {

  source = "./modules/ec2"

  for_each              = var.apps
  name                  = each.key
  instance_type         = var.instance_type
  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  allow_port            = var.allow_ports
  allow_sg_cidr         = var.allow_sg_cidr
  subnet_ids            = module.vpc.subnets[each.value["subnet_ref"]]
  bastion_nodes         = var.bastion_nodes
  capacity              = each.value["capacity"]
  asg                   = true




}