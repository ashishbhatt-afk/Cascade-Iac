# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=sqlmi.dev.terraform.tfstate" -backend-config="storage_account_name=Enter your storage account name here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
# terraform plan -var-file="dev.tfvars"
# terraform apply --auto-approve -var-file="dev.tfvars"

terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  json = {
    run = jsondecode(file("${path.module}/../../params/run.jsonc"))
  }

  tags = {
    ProdRef      = local.json.run.prodref
    ManagedBy    = local.json.run.managedby
    Environment  = local.json.run.envShort
    Workload     = var.workload
  }
}

# Remote state for core infrastructure
data "terraform_remote_state" "core" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "Enter your storage account name here"
    container_name       = "tfbackend"
    key                  = "core.${var.environment}.terraform.tfstate"
  }
}

# SQL MI Admin Password from Key Vault
data "azurerm_key_vault_secret" "sqlmipassword" {
  name         = "sqlmipassword"
  key_vault_id = data.terraform_remote_state.core.outputs.core-kv-id
}

# Current Tenant Info
data "azurerm_client_config" "current" {}

# Azure AD Group for SQL MI Admin
# data "azuread_group" "sql_admin_group" {
#   display_name = "cas-sql-admins"
# }

# SQL Managed Instance
resource "azurerm_mssql_managed_instance" "sqlmi" {
  name                         = var.mi_name_prefix
  resource_group_name          = data.terraform_remote_state.core.outputs.resource-group-name
  location                     = data.terraform_remote_state.core.outputs.rglocation
  license_type                 = "BasePrice"
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = 32
  subnet_id                    = data.terraform_remote_state.core.outputs.snet-sqlmi-id
  vcores                       = 4
  administrator_login          = var.sqladmin_username
  administrator_login_password = data.azurerm_key_vault_secret.sqlmipassword.value
  collation                    = "Latin1_General_CI_AS"
  identity {
    type = "SystemAssigned"
  }
  tags                         = local.tags
}

# # Assign the Entra ID group as AAD Admin on SQL MI
# resource "azurerm_mssql_managed_instance_active_directory_administrator" "aad_admin" {
#   managed_instance_id = azurerm_mssql_managed_instance.sqlmi.id
#   login_username      = data.azuread_group.sql_admin_group.display_name
#   object_id           = data.azuread_group.sql_admin_group.object_id
#   tenant_id           = data.azurerm_client_config.current.tenant_id
# }

