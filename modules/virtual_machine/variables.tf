variable "vm_count" {
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
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "network_interface_ids" {
  description = "List of network interface IDs to attach to the VMs"
  type        = list(string)
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Standard_LRS"
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

variable "identity_type" {
  description = "Type of identity to assign to the VM"
  type        = string
  default     = "SystemAssigned"
}

variable "subscription_id" {
  description = "Subscription ID for the Azure resources"
  type        = string
  default     = "enter your subscription id here"
  
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}  
}