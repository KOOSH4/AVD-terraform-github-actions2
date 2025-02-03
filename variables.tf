variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-AVD2-pool-dewc"
}
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure Region"
  default     = "westeurope"
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "bastion_name" {
  type        = string
  description = "Name of the Azure Bastion Host"
}

variable "bastion_public_ip_name" {
  type        = string
  description = "Name of the Public IP for Azure Bastion"
}

variable "nic_name" {
  type        = string
  description = "Name of the Network Interface for VM"
}

variable "vm_name" {
  type        = string
  description = "Name of the Virtual Machine"
}

variable "admin_username" {
  type        = string
  description = "Admin username for VM"
}

variable "admin_password" {
  type        = string
  description = "Admin password for VM"
  sensitive   = true
}

variable "hostpool_name" {
  type        = string
  description = "Name of the AVD Host Pool"
}

variable "application_group_name" {
  type        = string
  description = "Name of the AVD Application Group"
}

variable "workspace_name" {
  type        = string
  description = "Name of the AVD Workspace"
}
