# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=rsv.dev.terraform.tfstate" -backend-config="storage_account_name=enter your storage account here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
# terraform plan -var-file="dev.tfvars"
# terraform apply --auto-approve -var-file="dev.tfvars"


# backend configuration

terraform {
  backend "azurerm" {}
}

# provider


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

# Create a resource group for the Recovery Services Vault
resource "azurerm_resource_group" "rg-rsv" {
  name     = "rg-${var.environment}-rsv-cascade"
  location = var.resource_group_location
  tags = local.tags
}

# Create the Recovery Services Vault
resource "azurerm_recovery_services_vault" "rsv" {
  name                = "rsv-${var.environment}-cascade"
  location            = azurerm_resource_group.rg-rsv.location
  resource_group_name = azurerm_resource_group.rg-rsv.name
  sku                 = "Standard"
  public_network_access_enabled = true
  immutability                  = "Disabled"
  storage_mode_type            = "LocallyRedundant"
  cross_region_restore_enabled = false
  soft_delete_enabled          = false
  tags = local.tags
}

# Define the backup policy for VMs
resource "azurerm_backup_policy_vm" "rsvpp" {
  name                = "rsvpp-${var.environment}-cascade"
  resource_group_name = azurerm_resource_group.rg-rsv.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name

  backup {
    frequency = "Weekly"
    time      = "23:00"
    weekdays  = ["Monday"]
  }

  retention_weekly {
    weekdays = ["Monday"]
    count    = 7
  }

  # retention_monthly {
  #   weeks    = ["First", "Second"]
  #   weekdays = ["Monday", "Wednesday"]
  #   count    = 100
  # }

  # retention_yearly {
  #   months   = ["July"]
  #   weeks    = ["First", "Second"]
  #   weekdays = ["Monday", "Wednesday"]
  #   count    = 100
  # }

  instant_restore_retention_days = 5

}

