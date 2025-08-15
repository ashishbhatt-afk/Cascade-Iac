# locals {
#   json = {
#     run = jsondecode(file("${path.module}/../../params/run.jsonc"))
#   }
  
#   tags = {
#     ProdRef      = local.json.run.prodref
#     ManagedBy    = local.json.run.managedby
#     Environment  = local.json.run.envShort
#     Workload       = local.json.run.workload
#   }
# }


resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  tags = var.tags
}