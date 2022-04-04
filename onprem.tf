# RG for 'On-Prem' resources
resource "azurerm_resource_group" "onprem" {
  name     = "onprem-rg"
  location = "Southeast Asia"
}

resource "azurerm_network_security_group" "onprem-nsg" {
  name                = "onprem-nsg"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name

  security_rule {
    name                       = "AllowMySQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "192.168.0.0/16"
  }

  security_rule {
    name                       = "AllowPostgreSQL"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "192.168.0.0/16"
  }
  

  tags = {
    environment = "On-Premise"
  }
}

# VNET for the 'On-Prem' resources
resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
  address_space       = ["192.168.100.0/24"]

  subnet {
    name           = "onprem-vnet-subnet1"
    address_prefix = "192.168.100.0/26"
    security_group = azurerm_network_security_group.onprem-nsg.id
  }

  subnet {
    name           = "onprem-vnet-subnet2"
    address_prefix = "192.168.100.64/26"
  }

  tags = {
    environment = "On-Premise"
  }
}
