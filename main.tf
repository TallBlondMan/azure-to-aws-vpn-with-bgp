# My sub creates default resource group,
# and does not let you create a new one
# Hence the fetch data here :)
data "azurerm_resource_group" "this" {
  name = "1-aed87d6f-playground-sandbox"
}

#########################################
#               VNet
#########################################

resource "azurerm_virtual_network" "vnet" {
  name                = "AWS-Azure-VNet"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "gateway_subnet" {
  name = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = data.azurerm_resource_group.this.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "default_subnet" {
  name = "private-subnet-1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = data.azurerm_resource_group.this.name
  address_prefixes = ["10.0.0.0/24"]
}
#########################################
#        Virtual Network Gateway
#########################################

resource "azurerm_public_ip" "public_ip_1" {
  name = "publicIP-01"
  resource_group_name = data.azurerm_resource_group.this.name
  location = data.azurerm_resource_group.this.location

  allocation_method = "Dynamic"
}

resource "azurerm_public_ip" "public_ip_2" {
  name = "publicIP-02"
  resource_group_name = data.azurerm_resource_group.this.name
  location = data.azurerm_resource_group.this.location

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vng_to_aws" {
  name = "VPN-to-AWS"
  location = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  type = "Vpn"
  sku = "VpnGw2"
  active_active = true

  vpn_type = "RouteBased"
  enable_bgp = true
  
  ip_configuration {
    name = "VPN-PublicIP-01"
    public_ip_address_id = azurerm_public_ip.public_ip_1.id
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  ip_configuration {
    name = "VPN-PublicIP-02"
    public_ip_address_id = azurerm_public_ip.public_ip_2.id
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  bgp_settings {
    asn = 65000
    peering_addresses {
      ip_configuration_name = "VPN-PublicIP-01"
      apipa_addresses = ["169.254.21.2", "169.254.22.2"]
    }
    peering_addresses {
      ip_configuration_name = "VPN-PublicIP-02"
      apipa_addresses = ["169.254.21.6", "169.254.22.6"]
    }
  }
}

