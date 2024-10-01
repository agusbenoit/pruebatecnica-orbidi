output "private_subnet_ids" {
  value       = data.terraform_remote_state.global.outputs.private_subnet_ids
  description = "IDs de las subnets privadas donde se desplegarán las tareas Fargate"
}

output "ecs_service_security_group" {
  value       = aws_security_group.ecs_service_sg.id
  description = "Security Group ID para el servicio ECS"
}

output "alb_target_group_arn" {
  value       = module.load_balancer.target_group_arn
  description = "ARN del Target Group del Application Load Balancer"
}

output "alb_dns_name" {
  value       = module.load_balancer.alb_dns_name
  description = "DNS del Application Load Balancer"
}

output "task_execution_role" {
    value       = aws_iam_role.ecs_task_execution_role.arn
    description = "ARN del task execution role"
}