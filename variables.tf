variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
}

variable "vpc_name" {
  description = "AWS VPC name"
  type        = string
}

variable "vpc_enable_dns_hostnames" {
  description = "Enable/disable DNS hostnames in the VPC"
  type        = bool
}