variable "subscription_id" {
    type = string
    default = "enter your subscription id here"
}

variable "tenant_id" {
    type = string
    default = "enter your tenant id herec"
}

variable "build_resource_group_name" {
    type = string
    default = "rg-c2a-images"
}

variable "client_id" {
    type = string
    default = "enter your client id here"
}

#=>secret storage account key //////////////////////////////////////////////////////////////////////////////
variable "storageaccountkey" {
    type = string
    default = "unknown"
    sensitive = true
}

#=>secret client_secret
variable "client_secret" {
    type = string
    default = "unknown"
    sensitive = true
}


variable "image_sku" {
    type = string
    default = "2022-Datacenter"
}



variable "vm_size" {
    type = string
    default = "Standard_D2_v2"
}


variable "DD_API" {
    type = string
    default = ""
}

variable "managed_image_name" {
    type = string
    default = "image-cas"
}

variable "product" {
    type    = string
    default = "rdsserver"  // value should be either rdsserver or commonforwebandapp
}

variable "product_postfix" {
    type    = string
    default = ""
}

variable "branch" {
    type    = string
    default = ""
}

variable "build_id" {
    type    = string
    default = ""
}

locals {
    # If product_postfix is not set manually, derive it from product
    computed_product_postfix = (
        var.product == "commonforwebandapp" ? "webandapp" :
        var.product == "rdsserver" ? "rds" :
        var.product_postfix  # Use manually set value if none of the conditions match
    )
    product_managed_image_name = "${var.managed_image_name}-${var.branch}-${local.computed_product_postfix}-${var.build_id}"
}