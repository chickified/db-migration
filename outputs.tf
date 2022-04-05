output "mysql-instance-ip"{
    value = azurerm_public_ip.onprem-vm-pip.ip_address
}