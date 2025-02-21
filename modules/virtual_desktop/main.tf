resource "azurerm_virtual_desktop_host_pool" "this" {
  name                     = var.hostpool_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  type                     = "Pooled"
  maximum_sessions_allowed = 6
  load_balancer_type       = "BreadthFirst"
}

resource "azurerm_virtual_desktop_application_group" "this" {
  name                = var.application_group_name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.this.id
}

resource "azurerm_virtual_desktop_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.this.id
  expiration_date = timeadd(timestamp(), "48h")
}

output "hostpool_id" {
  value = azurerm_virtual_desktop_host_pool.this.id
}

output "registration_token" {
  value = azurerm_virtual_desktop_host_pool_registration_info.this.token
}
