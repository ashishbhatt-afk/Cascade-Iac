# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=rbq.dev.terraform.tfstate" -backend-config="storage_account_name=Enter your storage account name here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
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

# Retrieve core infrastructure state
data "terraform_remote_state" "core" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "Enter your storage account name here"      # The storage account for backend
    container_name       = "tfbackend"                                 # The container for tfstate
    key                  = "core.${var.environment}.terraform.tfstate" # The state file key of core infra
  }
}

data "azurerm_key_vault_secret" "rbqvmpassword" {
  name         = "rbqvmpassword"
  key_vault_id = data.terraform_remote_state.core.outputs.core-kv-id
}

# data "terraform_remote_state" "rsv" {
#   backend = "azurerm"
#   config = {
#     resource_group_name  = "rg-statefile-poc-cascade"
#     storage_account_name = "Storage account name here"
#     container_name       = "tfbackend"
#     key                  = "rsv.${var.environment}.terraform.tfstate" # this is what is going to be part of final code
#   }
# }

resource "azurerm_public_ip" "rbq_public_ip" {
  count               = var.rbq_count
  name                = format("${var.vm_name_prefix}-public-ip", count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name
  allocation_method   = "Static"
  tags = local.tags
}

resource "azurerm_network_interface" "rbq_nic" {
  count               = var.rbq_count
  name                = format("${var.vm_name_prefix}-nic",count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.terraform_remote_state.core.outputs.snet-rbq-id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(data.terraform_remote_state.core.outputs["subnet-rbq-address_prefixes"][0], count.index + 5)
    public_ip_address_id          = azurerm_public_ip.rbq_public_ip[count.index].id
    # private_ip_address            = cidrhost(local.iis_subnet_base_ip[0], count.index + 5) 
  }
  tags = local.tags
}

resource "azurerm_windows_virtual_machine" "rbq_vm" {
  count               = var.rbq_count
  name                = format("${var.vm_name_prefix}", count.index + 1)
  location            = data.terraform_remote_state.core.outputs.rglocation
  resource_group_name = data.terraform_remote_state.core.outputs.resource-group-name
  size                = var.vm_size
  admin_username      = var.user_name
  admin_password      = data.azurerm_key_vault_secret.rbqvmpassword.value
  network_interface_ids = [
    element(azurerm_network_interface.rbq_nic[*].id, count.index)
  ]

  os_disk {
    name                 = format("${var.vm_name_prefix}-osdisk",count.index + 1)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # source_image_reference {
  #   publisher = "MicrosoftWindowsServer"
  #   offer     = "WindowsServer"
  #   sku       = "2022-Datacenter"
  #   version   = "latest"
  # }

  source_image_id = "/subscriptions/76785675ew7e45647hjgdhfchstfct4/resourceGroups/rg-statefile-poc-cascade/providers/Microsoft.Compute/images/winweb2022-std-image"
  
  license_type = "Windows_Server"

  identity {
    type = "SystemAssigned"
  }
  # lifecycle {
  #   prevent_destroy = true
  # }
  tags = local.tags
}

// currently Rabbit MQ server is not behind load balancer

# resource "azurerm_network_interface_backend_address_pool_association" "nic_backend_association" {
#   count                   = var.rbq_count
#   network_interface_id    = azurerm_network_interface.rbq_nic[count.index].id
#   ip_configuration_name   = "internal"
#   backend_address_pool_id = data.terraform_remote_state.core.outputs.azure_lb_backend_address_pool_id
# }

# resource "azurerm_backup_protected_vm" "vm-policy-add" {
#   resource_group_name = data.terraform_remote_state.rsv.outputs.resource-group-name
#   recovery_vault_name = data.terraform_remote_state.rsv.outputs.recovery_vault_name
#   source_vm_id        = azurerm_windows_virtual_machine.rbq_vm[0].id
#   backup_policy_id    = data.terraform_remote_state.rsv.outputs.backup_policy_id
# }


resource "azurerm_virtual_machine_extension" "join-domain" {
  # depends_on = [ azurerm_backup_protected_vm.vm-policy-add ]
  name                       = "join-domain"
  virtual_machine_id         = azurerm_windows_virtual_machine.rbq_vm[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  # tags                       = merge({ "ResourceName" = "join-domain" }, var.tags, )

  settings = <<SETTINGS
    {
        "Name": "ngiris.com",
        "User": "ngiris.com\\domainjoin",
        "OUPath": "",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  
}

