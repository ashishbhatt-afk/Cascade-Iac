
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

variable "subscription_id" {
  description = "Subscription ID for the Azure resources"
  type        = string
  default     = "enter your subscription id here"
  
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  }

  variable "workload" {
    description = "The workload type"
    default     = "non-core"  
    
  }