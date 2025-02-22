variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-AVD2-pool-dewc"
}
variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "westeurope"
}

variable "vnet_name" {
  type        = string
  description = "The name of the Virtual Network"
}

variable "bastion_name" {
  type        = string
  description = "Name of the Azure Bastion Host"
}

variable "bastion_public_ip_name" {
  type        = string
  description = "The name of the Bastion Public IP"
}

variable "nic_name" {
  type        = string
  description = "The name of the network interface"
}

variable "vm_name" {
  type        = string
  description = "The name of the Virtual Machine"
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

variable "subscription_id" {
  type        = string
  description = "subscription id"
  sensitive   = true
}

variable "hostpool_name" {
  type        = string
  description = "The name of the AVD Host Pool"
}

variable "application_group_name" {
  type        = string
  description = "The name of the Application Group"
}

variable "workspace_name" {
  type        = string
  description = "The name of the Workspace"
}
variable "host_pool_name" {
  description = "The name of the AVD Host Pool"
  type        = string
}
