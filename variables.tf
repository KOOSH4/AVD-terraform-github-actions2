# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-AVD2-pool-dewc"
}

# Location Variables
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

# Network Variables
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

variable "avd_vnet_resource_group" {
  type        = string
  description = "Name of the resource group containing the AVD virtual network"
  default     = "rg-avd-network-001"
}

variable "avd_hostpool_subnet" {
  type        = string
  description = "Name of the subnet for AVD host pool"
  default     = "snet-avd-hostpool-001"
}

# Virtual Machine Variables
variable "NumberOfSessionHosts" {
  type        = number
  description = "Number of session host VMs to create"
  default     = 1
}

variable "vm_prefix" {
  type        = string
  description = "Prefix for VM names"
  default     = "avd-h1"
}

variable "avd_vnet" {
  type        = string
  description = "Name of the AVD Virtual Network"
}

variable "avd_Location" {
  description = "Azure region for AVD resources"
  type        = string
  default     = "westeurope"
}

variable "admin_username" {
  type        = string
  description = "Admin username for VMs"
}

variable "admin_password" {
  type        = string
  description = "Admin password for VMs"
  sensitive   = true
}

# AVD Service Variables
variable "hostpool_name" {
  type        = string
  description = "Name of the AVD Host Pool"
}

variable "workspace_name" {
  type        = string
  description = "Name of the AVD Workspace"
}

variable "application_group_name_desktopapp" {
  description = "Name of the AVD Application Group for Desktop Apps"
  type        = string
}

variable "application_group_name_remoteapp" {
  description = "Name of the AVD Application Group for Remote Apps"
  type        = string
}

# Storage Variables
variable "storage_account_name" {
  description = "Name of the storage account for FSLogix profiles"
  type        = string
  default     = "fslogixprofiles1wstrp"
}

# Authentication Variables
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  sensitive   = true
}

# Configuration Variables
variable "avd_agent_location" {
  type        = string
  description = "URL for the AVD agent configuration"
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_06-15-2022.zip"
}