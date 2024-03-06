variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "define environment"
  type        = string
  default     = "demo"
}

variable "application_name" {
  type        = string
  description = "Application Name"
}

variable "network_cidr" {
  type        = string
  description = "VPC CIDR Block"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRS blocks for Private Subnets"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRS blocks for Public Subnets"
}