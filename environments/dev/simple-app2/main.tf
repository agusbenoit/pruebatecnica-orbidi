data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "BUCKETTERRAFORM"   
    key    = "dev/global/terraform.tfstate"    
    region = "REGION"                   
  }
}


variable "name" {
  description = "Nombre de la aplicación"
  default     = "simple-app2"
}

module "load_balancer" {
  source            = "../../../modules/load_balancer"
  name              = "${var.name}-alb-dev"
  security_group    = aws_security_group.alb_sg.id
  subnets           = data.terraform_remote_state.global.outputs.public_subnet_ids
  target_group_name = "${var.name}-tg-dev"
  target_group_port = 8000
  vpc_id            = data.terraform_remote_state.global.outputs.vpc_id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg_${var.name}"
  description = "Security group for ALB of ${var.name}"
  vpc_id      = data.terraform_remote_state.global.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs_service_${var.name}_sg"
  description = "Security group for ECS ${var.name} service"
  vpc_id      = data.terraform_remote_state.global.outputs.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_service_${var.name}_sg"
    Environment = "dev"
  }
}