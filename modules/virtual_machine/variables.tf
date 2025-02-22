variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "vm_name" {
  description = "The name of the Virtual Machine"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}

variable "nic_name" {
  description = "The name of the network interface"
  type        = string
}

variable "network_interface_id" {
  description = "The ID of the network interface"
  type        = string
}

variable "host_pool_id" {
  description = "The ID of the AVD Host Pool"
  type        = string
}

variable "registration_token" {
  description = "The registration token for the AVD Host Pool"
  type        = string
  sensitive   = true
}

variable "host_pool_name" {
  description = "The name of the AVD Host Pool"
  type        = string
}
