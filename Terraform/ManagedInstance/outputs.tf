output "sqlmi_id" {
  value = azurerm_mssql_managed_instance.sqlmi.id
}

output "sqlmi_name" {
  value = azurerm_mssql_managed_instance.sqlmi.name
}

output "sqlmi_admin_login" {
  value = azurerm_mssql_managed_instance.sqlmi.administrator_login
}

output "sqlmi_fqdn" {
  value = azurerm_mssql_managed_instance.sqlmi.fqdn
}