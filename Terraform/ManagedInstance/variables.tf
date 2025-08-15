variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location for all resources."
}



# variable "sqlmi_count" {
#   description = "Number of SQL VMs"
#   type        = number
# }

variable "environment" {
  description = "environment"
  type        = string
  default     = ""
}

variable "sqladmin_username" {
  type        = string
  description = "The username for the local account that will be created on the new vm."
  default     = "sql-cas-admin"
}

variable "sqladminpassword" {
  description = "The password for the local account that will be created on the new vm."
  sensitive   = true
}

variable "subscription_id" {
  description = "subscription"
  default = "Enter your subscription id here"
}

variable "mi_name_prefix" {
  description = "The prefix for the VM names"
  type        = string
}

# variable "routetablename" {
#   description = "The prefix for the route table names"
#   type        = string
# }

variable "workload" {
  description = "The workload type"
  default     = "non-core"
  
}