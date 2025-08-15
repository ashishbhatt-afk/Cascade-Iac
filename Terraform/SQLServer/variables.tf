variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location for all resources."
}

variable "vm_size" {
  type        = string
  description = "The size of the vm to be created."
  default     = "Standard_B2ms"
}

variable "user_name" {
  type        = string
  description = "The username for the local account that will be created on the new vm."
  default     = "localadmin"
}

variable "sql_count" {
  description = "Number of SQL VMs"
  type        = number
}

variable "environment" {
  description = "environment"
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "subscription"
  default = "enter your subscription id here"
}

variable "vm_name_prefix" {
  description = "The prefix for the VM names"
  type        = string
}

variable "identity_type" {
    description = "System assigned identity for the VM"
    type        = string
    default     = "SystemAssigned"
    
  }

  variable "source_image_id" {
    description = "ID of the source image to use for the VM"
    type        = string
    default     = "/subscriptions/enter your subscription id here/resourceGroups/rg-statefile-poc-cascade/providers/Microsoft.Compute/images/winweb2022-std-image"
    
  }

  variable "license_type" {
    description = "License type for the VM"
    type        = string
    default     = "Windows_Server"
    
  }

  variable "os_disk_storage_account_type" {
    description = "Storage account type for the OS disk"
    type        = string
    default     = "Standard_LRS"
    
  }