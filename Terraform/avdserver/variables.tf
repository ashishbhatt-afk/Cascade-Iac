
variable "avd_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.40.0.0/28"]
}

variable "avd_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "avd_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.40.0.0/29"]
  
}

variable "location" {
  description = "Azure region where the VMs will be deployed"
  type        = string
  default     = "UK South"
}


variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B2ms"
}

variable "ProdRef" {
  description = "The product reference code from lens"
  type        = string
  default     = "HCMCASCAP0004"
}

variable "local_admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "localadmin"
}

variable "subscription_id" {
  description = "Subscription ID for the Azure resources"
  type        = string
  default     = "enter your subscription id here"
  
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
  }

  variable "identity_type" {
    description = "System assigned identity for the VM"
    type        = string
    default     = "SystemAssigned"
    
  }

  variable "source_image_id" {
    description = "ID of the source image to use for the VM"
    type        = string
    default     = "/subscriptions/Enter your Subscription id here/resourceGroups/rg-statefile-poc-cascade/providers/Microsoft.Compute/images/winweb2022-std-image"
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
    default     = "hub"
    
  }