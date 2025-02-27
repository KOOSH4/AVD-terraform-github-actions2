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

variable "StorageAccAccesskeys" {
  type        = string
  description = "Storage Account Access Key"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "subscription id"
  sensitive   = true
}

variable "hostpool_name" {
  type        = string
  description = "Name of the AVD Host Pool"
}


variable "workspace_name" {
  type        = string
  description = "Name of the AVD Workspace"
}


#########
variable "NumberOfSessionHosts" {
  type    = number
  default = 2
}

variable "vm_prefix" {
  type    = string
  default = "avd-h1"
}

variable "avd_vnet" {
  type    = string
  default = "vnet-avd-001"
}
variable "avd_vnet_resource_group" {
  type    = string
  default = "rg-avd-network-001"
}
variable "avd_hostpool_subnet" {
  type    = string
  default = "snet-avd-hostpool-001"
}

variable "avd_Location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "application_group_name_desktopapp" {
  description = "Name of the AVD Application Group for Desktop Apps"
  type        = string
}

variable "application_group_name_remoteapp" {
  description = "Name of the AVD Application Group for Remote Apps"
  type        = string
}