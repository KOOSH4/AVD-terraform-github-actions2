variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "vm_name" {
  description = "Name of the Virtual Machine"
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
  description = "Name of the Network Interface for VM"
  type        = string
}

variable "network_interface_id" {
  description = "ID of the network interface to attach to the VM"
  type        = string
}

variable "host_pool_id" {
  description = "ID of the Virtual Desktop Host Pool"
  type        = string
}

variable "registration_token" {
  description = "Registration token for the Virtual Desktop Host Pool"
  type        = string
  sensitive   = true
}
