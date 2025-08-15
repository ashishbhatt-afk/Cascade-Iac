# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=sql.dev.terraform.tfstate" -backend-config="storage_account_name=enter your storage account name here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
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
    Workload     = local.json.run.workload
  }
}

# Retrieve core infrastructure state
data "terraform_remote_state" "core" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "enter your storage account name here"      # The storage account for backend
    container_name       = "tfbackend"                                 # The container for tfstate
    key                  = "core.${var.environment}.terraform.tfstate" # The state file key of core infra
  }
}

data "terraform_remote_state" "rsv" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "enter your storage account name here"
    container_name       = "tfbackend"
    key                  = "rsv.${var.environment}.terraform.tfstate" # this is what is going to be part of final code
  }
}

data "azurerm_key_vault_secret" "sqlvmpassword" {
  name         = "sqlvmpassword"
  key_vault_id = data.terraform_remote_state.core.outputs.core-kv-id
}

resource "azurerm_public_ip" "sql_public_ip" {
  count               = var.sql_count
  name                = format("${var.vm_name_prefix}-public-ip", count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name
  allocation_method   = "Static"
  tags = local.tags
}

resource "azurerm_network_interface" "sql_nic" {
  count               = var.sql_count
  name                = format("${var.vm_name_prefix}-nic",count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.terraform_remote_state.core.outputs.snet-sql-id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(data.terraform_remote_state.core.outputs["subnet-sql-address_prefixes"][0], count.index + 5)
    
    # public_ip_address_id          = azurerm_public_ip.sql_public_ip[count.index].id
    # private_ip_address            = cidrhost(local.iis_subnet_base_ip[0], count.index + 5) 
  }
  tags = local.tags
}

module "vm" {
  source                       = "../../modules/virtual_machine"
  vm_count  = var.sql_count
  vm_name_prefix               = var.vm_name_prefix
  location                     = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name          = data.terraform_remote_state.core.outputs.resource-group-name
  vm_size                      = var.vm_size
  admin_username               = var.user_name
  admin_password               = data.azurerm_key_vault_secret.sqlvmpassword.value
  network_interface_ids        = azurerm_network_interface.sql_nic[*].id
  os_disk_storage_account_type = var.os_disk_storage_account_type
  source_image_id              = var.source_image_id
  license_type                 = var.license_type
  identity_type                = var.identity_type
  tags = local.tags
  }

resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_association" {
  count                   = var.sql_count
  network_interface_id    = azurerm_network_interface.sql_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = data.terraform_remote_state.core.outputs.azure_lb_backend_address_pool_id
}

resource "azurerm_backup_protected_vm" "vm-policy-add" {
  count               = var.sql_count
 resource_group_name = data.terraform_remote_state.rsv.outputs.resource-group-name
  recovery_vault_name = data.terraform_remote_state.rsv.outputs.recovery_vault_name
  source_vm_id        = module.vm.vm_id[count.index]
  backup_policy_id    = data.terraform_remote_state.rsv.outputs.backup_policy_id
}

resource "azurerm_virtual_machine_extension" "AADlogin" {
  count                 = var.sql_count
  name                  = "AADlogin"
  virtual_machine_id    = module.vm.vm_id[count.index]
  publisher             = "Microsoft.Azure.ActiveDirectory"
  type                  = "AADLoginForWindows"
  type_handler_version  = "2.2"
  auto_upgrade_minor_version = true
}

