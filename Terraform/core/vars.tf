# add variables

variable "resource_group_location" {
  description = "The region in which the resources"
  default     = "uksouth"
}

variable "subscription_id" {
  description = "subscription"
  default = "Enter your subscription id here"
}

variable "environment" {
  description = "The environment to deploy the resources"
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  
}

variable "snet_iis_address_prefix" {
  description = "The address space for the virtual network"
  
}

variable "snet_sql_address_prefix" {
  description = "The address space for the virtual network"
  
}

variable "snet_mgmt_address_prefix" {
  description = "The address space for the virtual network"
  
}

variable "snet_app_address_prefix" {
  description = "The address space for the virtual network"
  
}

variable "snet_sqlmi_address_prefix" {
  description = "The address space for the virtual network"
  
}

variable "snet_rbq_address_prefix" {
  description = "The address space for the virtual network"
  
}

variable "workload" {
  description = "The workload type"
  default     = "core"  
  
}