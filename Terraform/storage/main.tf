# Below commands are to be used when running from local machine
# terraform init -reconfigure -backend-config="resource_group_name=rg-statefile-poc-cascade" -backend-config="key=storage.dev.terraform.tfstate" -backend-config="storage_account_name=enter your storage account name here" -backend-config="container_name=tfbackend" -var-file="dev.tfvars"
# terraform plan -var-file="dev.tfvars"   
# terraform apply --auto-approve -var-file="dev.tfvars"


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


module "storage_account" {
  source              = "../../modules/storage_account"
  storage_account_name = "st${local.json.run.productShort}${local.json.run.envShort}${local.json.run.locationShort}"
  resource_group_name  = data.terraform_remote_state.core.outputs.resource-group-name
  location             = data.terraform_remote_state.core.outputs.rglocation
  account_tier         = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}