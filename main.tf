terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.17.0"
    }
  }

  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "rg-terraform-github-actions-AVD2"
    storage_account_name = "trfrmgthbactnstt"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {

  }
}

# Define any Azure resources to be created here. A simple resource group is shown here as a minimal example.
resource "azurerm_resource_group" "rg-AVD2" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Location = var.location
    Owner    = "Olad, Koosha"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg-AVD2.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnet_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg-AVD2.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_public_ip" "bastion_ip" {
  name                = var.bastion_public_ip_name
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  location            = azurerm_resource_group.rg-AVD2.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = azurerm_subnet.subnet_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}

resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                     = var.hostpool_name
  location                 = azurerm_resource_group.rg-AVD2.location
  resource_group_name      = azurerm_resource_group.rg-AVD2.name
  type                     = "Pooled"
  maximum_sessions_allowed = 6
  load_balancer_type       = "BreadthFirst"
}

resource "azurerm_virtual_desktop_application_group" "dag" {
  name                = var.application_group_name
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registration" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "48h") # Extended token validity
}
