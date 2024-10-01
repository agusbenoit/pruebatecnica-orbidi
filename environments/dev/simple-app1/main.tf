data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-2358974"   
    key    = "dev/global/terraform.tfstate"    
    region = "us-east-1"                   
  }
}


variable "name" {
  description = "Nombre de la aplicación"
  default     = "simple-app1"
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

resource "aws_ecs_service" "simple_app1_service" {
  name            = "simple-app1-service"
  cluster         = data.terraform_remote_state.global.outputs.ecs_cluster_id
  task_definition = "simple-app1" 
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.global.outputs.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.load_balancer.target_group_arn
    container_name   = "simple-app1"
    container_port   = 8000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [
      task_definition    #la definicion de la tarea va a ser manejada por el pipeline
    ]
  }

  depends_on = [module.load_balancer.listener_arn]
}
