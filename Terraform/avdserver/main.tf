# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=avd.terraform.tfstate" -backend-config="storage_account_name=enter your storage account name here" -backend-config="container_name=tfbackend"
# terraform plan 
# terraform apply --auto-approve

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
  resourceGroup = "rg-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}"
  tags = {
    ProdRef            = local.json.run.prodref
    ManagedBy         = local.json.run.managedby
    workload          = var.workload
  }
}

data "terraform_remote_state" "core-dev" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "Enter Actual stoarge account name here"
    container_name       = "tfbackend"
    key                  = "core.dev.terraform.tfstate" 
  }
}

data "terraform_remote_state" "core-staging" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "Enter Actual stoarge account name here"
    container_name       = "tfbackend"
    key                  = "core.staging.terraform.tfstate" 
  }
}

data "terraform_remote_state" "core-prod" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-statefile-poc-cascade"
    storage_account_name = "Enter Actual stoarge account name here"
    container_name       = "tfbackend"
    key                  = "core.prod.terraform.tfstate" 
  }
}



data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "avd-rg" {
  name     = local.resourceGroup
  location = local.json.run.location
  tags = local.tags
}

# create a key vault to store the AVD VM password
resource "azurerm_key_vault" "avd-kv" {
  name                        = "kv-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}"
  location                    = azurerm_resource_group.avd-rg.location
  resource_group_name         = azurerm_resource_group.avd-rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  enable_rbac_authorization = true
  tags = local.tags

  depends_on = [
    azurerm_resource_group.avd-rg
  ]
}

resource "random_password" "avdvm" {
  length           = 16
  special          = true
  upper            = true
  lower            = true
  numeric = true
  override_special = "!@#$%&*()-_=+"
}

resource "azurerm_key_vault_secret" "avdvmpassword" {
  name         = "avdvmpassword"
  value        = random_password.avdvm.result
  key_vault_id = azurerm_key_vault.avd-kv.id
}

resource "azurerm_virtual_network" "avd-vnet" {
  name                = "vnet-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}"
  address_space       = var.avd_address_space
  location            = azurerm_resource_group.avd-rg.location
  resource_group_name = azurerm_resource_group.avd-rg.name
  depends_on          = [azurerm_resource_group.avd-rg]
}

resource "azurerm_subnet" "avd_subnet" {
  name                 = "subnet-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name  = azurerm_resource_group.avd-rg.name
  virtual_network_name = azurerm_virtual_network.avd-vnet.name
  address_prefixes     = var.avd_address_prefixes
  depends_on           = [azurerm_resource_group.avd-rg]
}

resource "azurerm_network_security_group" "avd_nsg" {
  name                = "nsg-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}"
  location            = azurerm_resource_group.avd-rg.location
  resource_group_name = azurerm_resource_group.avd-rg.name
  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.avd-rg]
}

resource "azurerm_subnet_network_security_group_association" "avd_nsg_assoc" {
  subnet_id                 = azurerm_subnet.avd_subnet.id
  network_security_group_id = azurerm_network_security_group.avd_nsg.id
}

resource "azurerm_virtual_network_peering" "avd-to-dev" {
  name                      = "peer-${local.json.run.productShort}-avd-to-dev"
  resource_group_name       = azurerm_resource_group.avd-rg.name
  virtual_network_name      = azurerm_virtual_network.avd-vnet.name
  remote_virtual_network_id = data.terraform_remote_state.core-dev.outputs.vnet-id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "avd-to-prod" {
  name                      = "peer-${local.json.run.productShort}-avd-to-prod"
  resource_group_name       = azurerm_resource_group.avd-rg.name
  virtual_network_name      = azurerm_virtual_network.avd-vnet.name
  remote_virtual_network_id = data.terraform_remote_state.core-prod.outputs.vnet-id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "avd-to-staging" {
  name                      = "peer-${local.json.run.productShort}-avd-to-staging"
  resource_group_name       = azurerm_resource_group.avd-rg.name
  virtual_network_name      = azurerm_virtual_network.avd-vnet.name
  remote_virtual_network_id = data.terraform_remote_state.core-staging.outputs.vnet-id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

#  Vnet Peering for AVD to Dev, Prod and Staging Vnet is done but reverse peering is needed and is below:

resource "azurerm_virtual_network_peering" "dev-to-avd" {
  name                      = "peer-${local.json.run.productShort}-dev-to-avd"
  resource_group_name       = data.terraform_remote_state.core-dev.outputs.resource-group-name
  virtual_network_name      = data.terraform_remote_state.core-dev.outputs.vnet-name
  remote_virtual_network_id = azurerm_virtual_network.avd-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "prod-to-avd" {
  name                      = "peer-${local.json.run.productShort}-prod-to-avd"
  resource_group_name       = data.terraform_remote_state.core-prod.outputs.resource-group-name
  virtual_network_name      = data.terraform_remote_state.core-prod.outputs.vnet-name
  remote_virtual_network_id = azurerm_virtual_network.avd-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "staging-to-avd" {
  name                      = "peer-${local.json.run.productShort}-staging-to-avd"
  resource_group_name       = data.terraform_remote_state.core-staging.outputs.resource-group-name
  virtual_network_name      = data.terraform_remote_state.core-staging.outputs.vnet-name
  remote_virtual_network_id = azurerm_virtual_network.avd-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# ######################################## ## Below resource are for Creating AVD Host Pool

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "workspace-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}"
  resource_group_name = azurerm_resource_group.avd-rg.name
  location            = azurerm_resource_group.avd-rg.location
  friendly_name       = "Cascade Workspace"
  description         = "AVD Workspace for Cascade"
}


resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  resource_group_name      = azurerm_resource_group.avd-rg.name
  location                 = azurerm_resource_group.avd-rg.location
  name                     = "vdhp-${local.json.run.productShort}-0-${local.json.run.locationShort}-${var.workload}"
  friendly_name            = "vdhp-${local.json.run.productShort}-0-${local.json.run.locationShort}-${var.workload}"
  validate_environment     = true
  custom_rdp_properties = "audiocapturemode:i:1;audiomode:i:0;enablecredsspsupport:i:1;isaadjoin:i:1;enablerdsaadauth:i:1;redirectclipboard:i:1;"
  description              = "Terraform HostPool"
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "DepthFirst" 
  start_vm_on_connect = true
  tags = local.tags
  depends_on = [azurerm_resource_group.avd-rg]
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = "${timeadd(timestamp(), "24h")}"
}

resource "azurerm_virtual_desktop_application_group" "dag" {
  resource_group_name = azurerm_resource_group.avd-rg.name
  location            = azurerm_resource_group.avd-rg.location
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  type                = "Desktop"
  name                = "vdhp-${local.json.run.productShort}-${var.workload}-dag"
  friendly_name       = "Cascade AppGroup"
  description         = "Cascade AVD application group"
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool, azurerm_virtual_desktop_workspace.workspace]
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}

# ################################## end of resource for Creating AVD Host Pool #################################


#################################### Below are resources definition for the AVD hosts ##########################

resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.avd_count
  name                = "nic-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}-${count.index}"
  resource_group_name = azurerm_resource_group.avd-rg.name
  location            = azurerm_resource_group.avd-rg.location

  ip_configuration {
    name                          = "nic-ip-config-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}-${count.index}"
    primary                       = true
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [
    azurerm_resource_group.avd-rg,
    azurerm_virtual_network.avd-vnet
  ]
}

locals {
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
}


#DNS link part from AVD Vnet to VM Vnets
resource "azurerm_private_dns_zone_virtual_network_link" "avd-dev-dns-link" {
  name                  = "link-${local.json.run.productShort}-avd-dev"
  resource_group_name   = data.terraform_remote_state.core-dev.outputs.resource-group-name
  private_dns_zone_name = data.terraform_remote_state.core-dev.outputs.core-dnszone-name
  virtual_network_id    = azurerm_virtual_network.avd-vnet.id
  registration_enabled  = false
  depends_on = [azurerm_virtual_network.avd-vnet]
}

resource "azurerm_private_dns_zone_virtual_network_link" "avd-staging-dns-link" {
  name                  = "link-${local.json.run.productShort}-avd-staging"
  resource_group_name   = data.terraform_remote_state.core-staging.outputs.resource-group-name
  private_dns_zone_name = data.terraform_remote_state.core-staging.outputs.core-dnszone-name
  virtual_network_id    = azurerm_virtual_network.avd-vnet.id
  registration_enabled  = false
  depends_on = [azurerm_virtual_network.avd-vnet]
}

resource "azurerm_private_dns_zone_virtual_network_link" "avd-prod-dns-link" {
  name                  = "link-${local.json.run.productShort}-avd-prod"
  resource_group_name   = data.terraform_remote_state.core-prod.outputs.resource-group-name
  private_dns_zone_name = data.terraform_remote_state.core-prod.outputs.core-dnszone-name
  virtual_network_id    = azurerm_virtual_network.avd-vnet.id
  registration_enabled  = false
  depends_on = [azurerm_virtual_network.avd-vnet]
}

 ########################################## AVD Host resources ##########################################

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = var.avd_count
  name                  = "vm-${local.json.run.productShort}-${var.workload}-${count.index}"
  resource_group_name   = azurerm_resource_group.avd-rg.name
  location              = azurerm_resource_group.avd-rg.location
  size                  = var.vm_size
  network_interface_ids = [
    element(azurerm_network_interface.avd_vm_nic[*].id, count.index)
  ]

  provision_vm_agent    = true
  admin_username        = var.local_admin_username
  admin_password        = azurerm_key_vault_secret.avdvmpassword.value

  identity {
    type = "SystemAssigned"
  }
  os_disk {
    name                 = "os-disk-${local.json.run.productShort}-${local.json.run.locationShort}-${var.workload}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = var.source_image_id
  # source_image_reference {
  #   publisher = "MicrosoftWindowsServer"
  #   offer     = "windowsserver"
  #   sku       = "2022-datacenter"
  #   version   = "latest"
  # }

  license_type = "Windows_Server"

  depends_on = [
    azurerm_resource_group.avd-rg,
    azurerm_network_interface.avd_vm_nic
  ]
  tags = local.tags
}

# ########################################## End of AVD Host resources ##########################################
#custom script to set the timezone to UK

resource "azurerm_virtual_machine_extension" "avd_agent_registration" {
  count = var.avd_count
  name                = "avdagentregistration-${count.index}"
  virtual_machine_id  = azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_01-19-2023.zip",
      "ConfigurationFunction": "Configuration.ps1\\AddSessionHost",
      "Properties": {
        "hostPoolName":"${azurerm_virtual_desktop_host_pool.hostpool.name}",
        "aadjoin": true
      }
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
  PROTECTED_SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.avd_vm,
    azurerm_virtual_desktop_host_pool.hostpool
  ]
}

resource "azurerm_virtual_machine_extension" "set_uk_locale" {
  count                = var.avd_count
  name                 = "SetUKLocale"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris          = ["https://blob.core.windows.net/scripts/Set_UK_SystemLocale.ps1"]
    commandToExecute  = "powershell -ExecutionPolicy Unrestricted -File Set_UK_SystemLocale.ps1"
  })

  depends_on = [
    azurerm_virtual_machine_extension.avd_agent_registration,
    azurerm_virtual_machine_extension.AADlogin,
  ]
}

resource "azurerm_virtual_machine_extension" "AADlogin" {
  count                 = var.avd_count
  name                  = "AADLoginForWindows"
  virtual_machine_id    = azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher             = "Microsoft.Azure.ActiveDirectory"
  type                  = "AADLoginForWindows"
  type_handler_version  = "2.2"
  auto_upgrade_minor_version = true
}