
resource "azurerm_resource_group" "migrationdb-rg" {
  name     = "migrationdb-rg"
  location = "Southeast Asia"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "migrationdb-fw-allowonprem" {
  name                = "AllowOnPrem"
  resource_group_name = azurerm_resource_group.migrationdb-rg.name
  server_name         = azurerm_mysql_flexible_server.migrationdb-mysql.name
  start_ip_address    = azurerm_public_ip.onprem-vm-pip.ip_address
  end_ip_address      = azurerm_public_ip.onprem-vm-pip.ip_address
}

resource "azurerm_mysql_flexible_server" "migrationdb-mysql" {
  name                   = "migrationdb-mysql"
  resource_group_name    = azurerm_resource_group.migrationdb-rg.name
  location               = azurerm_resource_group.migrationdb-rg.location
  administrator_login    = "mysqladmin"
  administrator_password = "P@ssw0rd12345"
  version = "5.7"

  sku_name               = "B_Standard_B1s"

  depends_on = [
    azurerm_public_ip.onprem-vm-pip
  ]
}