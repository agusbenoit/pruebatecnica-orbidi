variable "name" {
  description = "Nombre del load balancer"
}

variable "security_group" {
  description = "ID del Security Group para el Load Balancer"
}

variable "subnets" {
  description = "IDs de las subredes para el Load Balancer"
}

variable "target_group_name" {
  description = "Nombre del Target Group"
}

variable "target_group_port" {
  description = "Puerto del Target Group"
}

variable "vpc_id" {
  description = "ID de la VPC"
}