variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "bastion_public_ip_name" {
  description = "The name of the Bastion public IP"
  type        = string
}


variable "nic_name" {
  description = "The name of the network interface"
  type        = string
}