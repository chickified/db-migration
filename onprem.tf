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
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMySQL"
    priority                   = 200
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
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "192.168.0.0/16"
  }
  
  security_rule {
    name                       = "AllowICMP"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# VNET for the 'On-Prem' resources
resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
  address_space       = ["192.168.100.0/24"]
}

resource "azurerm_subnet" "onprem-vnet-subnet1" {
  name                 = "onprem-vnet-subnet1"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem-vnet.name
  address_prefixes     = ["192.168.100.0/26"]
  depends_on = [
    azurerm_virtual_network.onprem-vnet
  ]
}

resource "azurerm_public_ip" "onprem-vm-pip" {
  name                = "onpre-vm-pip"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "onprem-vm-nic" {
  name                = "onprem-vm-nic"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
  depends_on = [
    azurerm_public_ip.onprem-vm-pip
  ]

  ip_configuration {
    name                          = "onprem-vm-nic"
    subnet_id                     = azurerm_subnet.onprem-vnet-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.onprem-vm-pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.onprem-vm-nic.id
  network_security_group_id = azurerm_network_security_group.onprem-nsg.id
  depends_on = [
    azurerm_network_security_group.onprem-nsg,
    azurerm_network_interface.onprem-vm-nic
  ]
}

resource "azurerm_virtual_machine" "onprem-vm" {
  name                  = "onprem-vm-mysql-instance"
  location              = azurerm_resource_group.onprem.location
  resource_group_name   = azurerm_resource_group.onprem.name
  network_interface_ids = [azurerm_network_interface.onprem-vm-nic.id]
  vm_size               = "Standard_B1ls"
  depends_on = [
    azurerm_network_interface.onprem-vm-nic,
    azurerm_public_ip.onprem-vm-pip
  ]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "onprem-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "onprem-vm-mysql-instance"
    admin_username = "azureuser"
    admin_password = "P@ssw0rd12345"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "vm-ext" {
  name                 = "onprem-vm-ext"
  virtual_machine_id = azurerm_virtual_machine.onprem-vm.id
  
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"

  settings = <<SETTINGS
  {
    "fileUris": [
      "https://nleescripts.blob.core.windows.net/scripts/download_scripts.sh"
    ],
    "commandToExecute": "cp download_scripts.sh /home/azureuser/download_scripts.sh"
  }
SETTINGS

}
