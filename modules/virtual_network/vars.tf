# add variables

variable "resource_group_location" {
  description = "The region in which the resources"
  default     = "uksouth"
}

variable "subscription_id" {
  description = "subscription"
  default = "enter your subscription id here"
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

variable "snet_app_address_prefix" {
  description = "The address space for the virtual network"
  
}