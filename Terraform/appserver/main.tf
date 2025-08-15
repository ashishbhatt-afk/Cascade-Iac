# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=app.dev.terraform.tfstate" -backend-config="storage_account_name=Actual_backend_storage account name here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
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
    Workload       = var.workload
  }
}

# Retrieve core infrastructure state
data "terraform_remote_state" "core" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "enter your storage account name here"
    container_name       = "tfbackend"
    key                  = "core.${var.environment}.terraform.tfstate" 
  }
}

data "terraform_remote_state" "rsv" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "enter your storage account name here"
    container_name       = "tfbackend"
    key                  = "rsv.${var.environment}.terraform.tfstate" 
  }
}

data "azurerm_key_vault_secret" "appvmpassword" {
  name         = "appvmpassword"
  key_vault_id = data.terraform_remote_state.core.outputs.core-kv-id
}

resource "azurerm_public_ip" "app_public_ip" {
  count               = contains(["dev", "staging"], var.environment) ? var.app_count : 0
  name                = format("${var.vm_name_prefix}-public-ip", count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name
  allocation_method   = "Static"
  tags = local.tags
}

resource "azurerm_network_interface" "app_nic" {
  count               = var.app_count
  name                = format("${var.vm_name_prefix}-nic",count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.terraform_remote_state.core.outputs.snet-app-id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(data.terraform_remote_state.core.outputs["subnet-app-address_prefixes"][0], count.index + 5)
    public_ip_address_id          = contains(["dev", "staging"], var.environment) ? azurerm_public_ip.app_public_ip[count.index].id : null
  }
  tags = local.tags
}

module "vm" {
  source                       = "../../modules/virtual_machine"
  vm_count  = var.app_count
  vm_name_prefix               = var.vm_name_prefix
  location                     = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name          = data.terraform_remote_state.core.outputs.resource-group-name
  vm_size                      = var.vm_size
  admin_username               = var.admin_username
  admin_password               = data.azurerm_key_vault_secret.appvmpassword.value
  network_interface_ids        = azurerm_network_interface.app_nic[*].id
  os_disk_storage_account_type = var.os_disk_storage_account_type
  source_image_id              = var.source_image_id
  license_type                 = var.license_type
  identity_type                = var.identity_type
  tags                         = local.tags
  }


resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_association" {
  count                   = var.app_count
  network_interface_id    = azurerm_network_interface.app_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = data.terraform_remote_state.core.outputs.azure_lb_backend_address_pool_id
}

resource "azurerm_backup_protected_vm" "vm-policy-add" {
  count               = var.app_count
  resource_group_name = data.terraform_remote_state.rsv.outputs.resource-group-name
  recovery_vault_name = data.terraform_remote_state.rsv.outputs.recovery_vault_name
  source_vm_id        = module.vm.vm_id[count.index]
  backup_policy_id    = data.terraform_remote_state.rsv.outputs.backup_policy_id
}

resource "azurerm_virtual_machine_extension" "AADlogin" {
  count                 = var.app_count
  name                  = "AADlogin"
  virtual_machine_id    = module.vm.vm_id[count.index]
  publisher             = "Microsoft.Azure.ActiveDirectory"
  type                  = "AADLoginForWindows"
  type_handler_version  = "2.2"
  auto_upgrade_minor_version = true
}

#custom script to run post deployment scripts

resource "azurerm_virtual_machine_extension" "Postdeploymentscript" {
  count                = var.app_count
  name                 = "Postdeploymentscript"
  virtual_machine_id   = module.vm.vm_id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris = [
      "enter your storage blob url here"
    ]
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File postdeploymentscripts.ps1"
  })
}