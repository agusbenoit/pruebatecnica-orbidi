variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDR blocks para subnets privadas"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDR blocks para subnets publicas"
  type        = list(string)
}

variable "availability_zones" {
  description = "Lista de availability zones"
  type        = list(string)
}

variable "vpc_name" {
  description = "Nombre de la VPC"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
