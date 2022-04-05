output "mysql-instance-ip"{
    value = azurerm_public_ip.onprem-vm-pip.ip_address
}

output "azuresql-instance-name"{
    value = azurerm_mysql_flexible_server.migrationdb-mysql.fqdn
}