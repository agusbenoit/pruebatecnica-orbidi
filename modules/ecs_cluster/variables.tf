variable "cluster_name" {
  description = "Nombre del cluster ECS"
}

variable "tags" {
  description = "Etiquetas para los recursos"
  type        = map(string)
  default     = {}
}