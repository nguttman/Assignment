variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
}

variable "allowed_ips" {
  description = "List of allowed IP addresses"
  type        = list(string)
}