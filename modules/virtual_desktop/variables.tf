variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "hostpool_name" {
  description = "The name of the AVD Host Pool"
  type        = string
}

variable "application_group_name" {
  description = "The name of the AVD Application Group"
  type        = string
}

variable "workspace_name" {
  description = "The name of the AVD Workspace"
  type        = string
}
