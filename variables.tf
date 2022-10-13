variable "environment" {
  description = "Environment ex: dev,prod or uat"
}

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

variable "log_bucket_arn" {
  description = "Bucket ARN to send vpc logs"
  type        = string
  default     = ""
}

variable "log_max_aggregation_interval" {
  description = "flow log aggregation interval in seconds"
  type        = number
  default = 30
}


variable "public_subnets" {
  description = "ec2 subnets cidr list"
  type = list(object({
    index     = number
    cidr      = string
    subnet_az = string
  }))
  default = []
}

variable "ec2_subnets" {
  description = "ec2 subnets cidr list"
  type = list(object({
    index     = number
    cidr      = string
    subnet_az = string
  }))
  default = []
}

variable "rds_subnets" {
  description = "subnets cidr list"
  type = list(object({
    index     = number
    cidr      = string
    subnet_az = string
  }))
  default = []
}
variable "elasticache_subnets" {
  description = "subnets cidr list"
  type = list(object({
    index     = number
    cidr      = string
    subnet_az = string
  }))
  default = []
}

variable "eks_subnets" {
  description = "subnets cidr list"
  type = list(object({
    index        = number
    cluster_name = string
    cidr         = string
    subnet_az    = string
    tags         = any
  }))
  default = []
}
