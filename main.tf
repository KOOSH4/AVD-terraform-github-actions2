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
