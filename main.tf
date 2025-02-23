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



resource "azurerm_virtual_desktop_workspace_application_group_association" "dag_workspace_assoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
}
#### FSLOGIX ####

resource "azurerm_storage_account" "fslogix_storage" {
  name                       = "fslogixavdeuw1"
  resource_group_name        = azurerm_resource_group.rg-AVD2.name
  location                   = azurerm_resource_group.rg-AVD2.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_share" "fslogix_share" {
  name               = "fslogixprofiles"
  storage_account_id = azurerm_storage_account.fslogix_storage.id
  quota              = 100 # Storage in GB
}
