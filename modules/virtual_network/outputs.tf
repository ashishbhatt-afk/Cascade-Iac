#  write all the outputs here

# Resource group

output "resource-group-id" {
  value = azurerm_resource_group.rg-core.id
}

output "resource-group-name" {
  value = azurerm_resource_group.rg-core.name
}

output "rglocation" {
  value = azurerm_resource_group.rg-core.location
}

# ///////////////////////////////////

# Network outputs

output "vnet-id" {
  value = azurerm_virtual_network.vnet-cascade.id
}

output "snet-iis-id" {
  value = azurerm_subnet.snet-iis.id
} 

output "snet-sql-id" {
  value = azurerm_subnet.snet-sql.id
}

output "snet-app-id" {
  value = azurerm_subnet.snet-app.id
}


output "subnet-iis-address_prefixes" {
  value = azurerm_subnet.snet-iis.address_prefixes
}

output "subnet-sql-address_prefixes" {
  value = azurerm_subnet.snet-sql.address_prefixes
  
}

output "subnet-app-address_prefixes" {
  value = azurerm_subnet.snet-app.address_prefixes
}


# NSG Outputs

output "nsg-iis-id" {
  value = azurerm_network_security_group.nsg-iis.id
}

output "nsg-sql-id" {
  value = azurerm_network_security_group.nsg-sql.id
}

output "nsg-app-id" {
  value = azurerm_network_security_group.nsg-app.id
}

# load balancer outputs

output "lb-id" {
  value = azurerm_lb.lb.id
}

output "lb-name" {
  value = azurerm_lb.lb.name
}

output "lb-public-ip-id" {
  value = azurerm_public_ip.lb-ip.id
}

output "azure_lb_backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}