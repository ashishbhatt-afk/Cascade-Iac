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

variable "rbq_count" {
  description = "Number of RabbitMQ VMs"
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

variable "workload" {
  description = "The workload type"
  default     = "non-core"
  
}