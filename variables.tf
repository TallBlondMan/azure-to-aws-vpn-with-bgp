variable "azure_rg_name" {
  type    = string
  default = "1-f712a34c-playground-sandbox"
}

variable "main_region" {
  type    = string
  default = "us-east-1"
}

variable "azure_resource_group" {
  type    = string
  default = ""
}

variable "aws_vpc_name" {
  type    = string
  default = "Azure-AWS-VPC"
}

variable "azure_vnet_name" {
  type    = string
  default = "AWS-Azure-VNet"
}

variable "azure_bgp_asn" {
  type    = number
  default = 65000
}

variable "aws_bgp_asn" {
  type    = string
  default = "64512"
}

variable "tunnel1_key" {
  type        = string
  description = "PSK key for tunnel 1 - export via TF_VAR_"
  default     = "pomidorekogoreczekgolonka"
}

variable "tunnel2_key" {
  type        = string
  description = "PSK key for tunnel 2 - export via TF_VAR_"
  default     = "pomidorekogoreczekgolonka"
}

variable "apipa_cidr_blocks" {
  type        = list(string)
  description = "4 element list of APIPA CIDR blocks, they have to be in 169.254.21.0 and 169.254.22.255 range of mask /30"
  default     = ["169.254.21.0/30", "169.254.22.0/30", "169.254.21.4/30", "169.254.22.4/30"]
}