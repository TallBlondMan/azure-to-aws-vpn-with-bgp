variable "azure_rg_name" {
  type    = string
  default = "1-7610fc1a-playground-sandbox"
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
  type    = string
  default = "pomidorekpomidorekgolonka"
}

variable "tunnel2_key" {
  type    = string
  default = "pomidorekpomidorekgolonka"
}