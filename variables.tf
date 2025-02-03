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