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

variable "workload" {
  description = "The workload type"
  default     = "rsv"  
}