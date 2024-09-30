locals {
  aws_region = "REGION"
}

module "networking" {
  source              = "../../../modules/networking"
  vpc_cidr            = "10.0.0.0/16"
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"] 
  availability_zones   = ["${local.aws_region}a", "${local.aws_region}b"]
  vpc_name             = "vpc-dev"
  tags = {
    Environment = "dev"
  }
}

module "ecs_cluster" {
  source       = "../../../modules/ecs_cluster"
  cluster_name = "ecs-cluster-dev"
}