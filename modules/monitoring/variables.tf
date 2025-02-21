variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "vm_id" {
  description = "The ID of the Virtual Machine"
  type        = string
}

variable "hostpool_id" {
  description = "The ID of the AVD Host Pool"
  type        = string
}
