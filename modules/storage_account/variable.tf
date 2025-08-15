variable "storage_account_name" {
  description = "The name of the Storage Account"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region where the storage account will be deployed"
  type        = string
  default     = "UK South"
}

variable "account_tier" {
  description = "The performance tier of the Storage Account (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The replication type of the Storage Account (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}