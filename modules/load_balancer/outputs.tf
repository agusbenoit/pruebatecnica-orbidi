output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN del listener HTTP"
  value       = aws_lb_listener.http.arn
}
