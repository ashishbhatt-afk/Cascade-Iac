variable "web_count" {
  description = "Number of VMs to create"
  type        = number
}

variable "vm_name_prefix" {
  description = "Prefix for the VM names"
  type        = string
}

variable "location" {
  description = "Azure region where the VMs will be deployed"
  type        = string
  default     = "UK South"
}

variable "ProdRef" {
  description = "The product reference code from lens"
  type        = string
  default     = "HCMCASCAP0004"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}


variable "subscription_id" {
  description = "Subscription ID for the Azure resources"
  type        = string
  default     = "enter your subscription id here"
  
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
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

  variable "workload" {
    description = "Workload type (e.g., core, non-core)"
    type        = string
    default     = "non-core"
    
  }