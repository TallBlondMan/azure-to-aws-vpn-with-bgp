#########################################
#                 AZURE
#########################################
# My sub creates default resource group,
# and does not let you create a new one
# Hence the fetch data here :)
data "azurerm_resource_group" "this" {
  name = var.azure_rg_name
}

locals {
  number_of_public_address = 2

}
#########################################
#                 VNet
#########################################

resource "azurerm_virtual_network" "vnet" {
  name                = var.azure_vnet_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "default_subnet" {
  name                 = "private-subnet-1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.this.name
  address_prefixes     = ["10.0.0.0/24"]
}
#########################################
#        Virtual Network Gateway
#########################################

resource "azurerm_public_ip" "public_ip" {
  count = local.number_of_public_address

  name = "public-IP-${count.index}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  allocation_method = "Dynamic"
}

data "azurerm_public_ip" "public_ip_data" {
  count = length(azurerm_public_ip.public_ip)

  name = azurerm_public_ip.public_ip[count.index].name
  resource_group_name = data.azurerm_resource_group.this.name

  depends_on = [ azurerm_virtual_network_gateway.vng_to_aws ]
}

resource "azurerm_virtual_network_gateway" "vng_to_aws" {
  name                = "VPN-to-AWS"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  type          = "Vpn"
  sku           = "VpnGw2"
  generation    = "Generation2"
  active_active = true

  vpn_type   = "RouteBased"
  enable_bgp = true

  ip_configuration {
    name                 = "VPN-PublicIP-01"
    public_ip_address_id = azurerm_public_ip.public_ip[0].id
    subnet_id            = azurerm_subnet.gateway_subnet.id
  }

  ip_configuration {
    name                 = "VPN-PublicIP-02"
    public_ip_address_id = azurerm_public_ip.public_ip[1].id
    subnet_id            = azurerm_subnet.gateway_subnet.id
  }

  bgp_settings {
    asn = 65000
    peering_addresses {
      ip_configuration_name = "VPN-PublicIP-01"
      apipa_addresses       = [
        cidrhost(var.apipa_cidr_blocks[0], 2), # "169.254.21.2"
        cidrhost(var.apipa_cidr_blocks[1], 2)  # "169.254.22.2"
      ]
    }
    peering_addresses {
      ip_configuration_name = "VPN-PublicIP-02"
      apipa_addresses       = [
        cidrhost(var.apipa_cidr_blocks[2], 2), # "169.254.21.6"
        cidrhost(var.apipa_cidr_blocks[3], 2)  # "169.254.22.6"
      ]
    }
  }
}

resource "azurerm_virtual_network_gateway_connection" "tunnel1-connection1" {
  name                = "tunnel1-connection1"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng_to_aws.id

  enable_bgp               = true
  shared_key               = var.tunnel1_key
  local_network_gateway_id = azurerm_local_network_gateway.aws_tunnel1-1.id
  custom_bgp_addresses {
    primary   = cidrhost(var.apipa_cidr_blocks[0], 2) # "169.254.21.2"
    secondary = cidrhost(var.apipa_cidr_blocks[2], 2) # "169.254.21.6"
  }

  depends_on = [
    aws_vpn_connection.vpn_to_azure_1,
    aws_vpn_connection.vpn_to_azure_2
  ]
}

resource "azurerm_virtual_network_gateway_connection" "tunnel2-connection1" {
  name                = "tunnel2-connection1"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng_to_aws.id

  enable_bgp               = true
  shared_key               = var.tunnel2_key
  local_network_gateway_id = azurerm_local_network_gateway.aws_tunnel1-2.id
  custom_bgp_addresses {
    primary   = cidrhost(var.apipa_cidr_blocks[1], 2) # "169.254.22.2"
    secondary = cidrhost(var.apipa_cidr_blocks[3], 2) # "169.254.22.6"
  }

  depends_on = [
    aws_vpn_connection.vpn_to_azure_1,
    aws_vpn_connection.vpn_to_azure_2
  ]
}

resource "azurerm_virtual_network_gateway_connection" "tunnel1-connection2" {
  name                = "tunnel1-connection2"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng_to_aws.id

  enable_bgp               = true
  shared_key               = var.tunnel1_key
  local_network_gateway_id = azurerm_local_network_gateway.aws_tunnel2-1.id
  custom_bgp_addresses {
    primary   = cidrhost(var.apipa_cidr_blocks[0], 2) # "169.254.21.2"
    secondary = cidrhost(var.apipa_cidr_blocks[2], 2) # "169.254.21.6"
  }

  depends_on = [
    aws_vpn_connection.vpn_to_azure_1,
    aws_vpn_connection.vpn_to_azure_2
  ]
}

resource "azurerm_virtual_network_gateway_connection" "tunnel2-connection2" {
  name                = "tunnel2-connection2"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng_to_aws.id

  enable_bgp               = true
  shared_key               = var.tunnel2_key
  local_network_gateway_id = azurerm_local_network_gateway.aws_tunnel2-2.id
  custom_bgp_addresses {
    primary   = cidrhost(var.apipa_cidr_blocks[0], 2) # "169.254.21.2"
    secondary = cidrhost(var.apipa_cidr_blocks[3], 2) # "169.254.22.6"
  }

  depends_on = [
    aws_vpn_connection.vpn_to_azure_1,
    aws_vpn_connection.vpn_to_azure_2
  ]
}
#########################################
#       Local Network Connections
#########################################

resource "azurerm_local_network_gateway" "aws_tunnel1-1" {
  name                = "AWS-Tunnel1-1"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  gateway_address = aws_vpn_connection.vpn_to_azure_1.tunnel1_address

  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost(var.apipa_cidr_blocks[0], 1) # "169.254.21.1"
  }
}

resource "azurerm_local_network_gateway" "aws_tunnel1-2" {
  name                = "AWS-Tunnel1-2"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  gateway_address = aws_vpn_connection.vpn_to_azure_1.tunnel2_address

  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost(var.apipa_cidr_blocks[1], 1) # "169.254.22.1"
  }
}

resource "azurerm_local_network_gateway" "aws_tunnel2-1" {
  name                = "AWS-Tunnel2-1"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  gateway_address = aws_vpn_connection.vpn_to_azure_2.tunnel1_address

  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost(var.apipa_cidr_blocks[2], 1) # "169.254.21.5"
  }
}

resource "azurerm_local_network_gateway" "aws_tunnel2-2" {
  name                = "AWS-Tunnel2-2"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  gateway_address = aws_vpn_connection.vpn_to_azure_2.tunnel2_address

  bgp_settings {
    asn                 = var.aws_bgp_asn
    bgp_peering_address = cidrhost(var.apipa_cidr_blocks[3], 1) # "169.254.22.5"
  }
}

#########################################
#                 AWS
#########################################
data "aws_availability_zones" "available" {
  state = "available"
}

#########################################
#                 VPC
#########################################
resource "aws_vpc" "vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = var.aws_vpc_name
  }
}

resource "aws_subnet" "private-1" {
  cidr_block        = "10.1.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "private-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_subnet" "public-1" {
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "public-${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}

resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  propagating_vgws       = [aws_vpn_gateway.virtual_private_gateway.id]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "AWS-Azure-RT"
  }
}
#########################################
#            VPN Components
#########################################
resource "aws_vpn_gateway" "virtual_private_gateway" {
  vpc_id = aws_vpc.vpc.id
  # Default ASB of AWS
  amazon_side_asn = var.aws_bgp_asn # "64512"
  tags = {
    Name = "VPN-to-Azure"
  }
}

resource "time_sleep" "wait_for_ip_assignment" {
  depends_on = [
    azurerm_virtual_network_gateway.vng_to_aws
  ]

  create_duration = "30s"
}

resource "aws_customer_gateway" "customet_gw" {
  count = length(data.azurerm_public_ip.public_ip)

  bgp_asn = tostring(var.azure_bgp_asn) # "65000"
  type    = "ipsec.1"

  ip_address = data.azurerm_public_ip.public_ip[count.index].ip_address

  depends_on = [
    time_sleep.wait_for_ip_assignment
  ]
}
# resource "aws_customer_gateway" "customet_gw_1" {
#   bgp_asn = tostring(var.azure_bgp_asn) # "65000"
#   type    = "ipsec.1"

#   ip_address = azurerm_public_ip.public_ip_1.ip_address

#   depends_on = [
#     time_sleep.wait_for_ip_assignment
#   ]
# }

# resource "aws_customer_gateway" "customet_gw_2" {
#   bgp_asn = tostring(var.azure_bgp_asn) # "65000"
#   type    = "ipsec.1"

#   ip_address = azurerm_public_ip.public_ip_2.ip_address

#   depends_on = [
#     time_sleep.wait_for_ip_assignment
#   ]
# }

#########################################
#            Site-to-Site
#########################################
resource "aws_vpn_connection" "vpn_to_azure_1" {
  vpn_gateway_id      = aws_vpn_gateway.virtual_private_gateway.id
  customer_gateway_id = aws_customer_gateway.customet_gw[0].id
  type                = "ipsec.1"

  tunnel1_inside_cidr   = var.apipa_cidr_blocks[0] # "169.254.21.0/30"
  tunnel1_preshared_key = var.tunnel1_key

  tunnel2_inside_cidr   = var.apipa_cidr_blocks[1] # "169.254.22.0/30"
  tunnel2_preshared_key = var.tunnel2_key
}

resource "aws_vpn_connection" "vpn_to_azure_2" {
  vpn_gateway_id      = aws_vpn_gateway.virtual_private_gateway.id
  customer_gateway_id = aws_customer_gateway.customet_gw[1].id
  type                = "ipsec.1"

  tunnel1_inside_cidr   = var.apipa_cidr_blocks[2] # "169.254.21.4/30"
  tunnel1_preshared_key = var.tunnel1_key

  tunnel2_inside_cidr   = var.apipa_cidr_blocks[3] # "169.254.22.4/30"
  tunnel2_preshared_key = var.tunnel2_key
}

#TODO
# 1. Make the option to supply existing VPC and Vnet - use data to retrive??
# 2. Get rid of repeating code
# 3. Variablize the setup
#   - ASN
#   - network and subnet CIDR
# 4. Add the APIPA customization
# 5. Wait for the IP to get assigned