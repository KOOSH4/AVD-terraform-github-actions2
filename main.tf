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

# Create a storage account for FSLogix profile storage
resource "azurerm_storage_account" "FSLogixStorageAccount" {
  name                     = "fslogixavdeuw1"
  location                 = azurerm_resource_group.rg-AVD2.location
  resource_group_name      = azurerm_resource_group.rg-AVD2.name
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
}

resource "azurerm_storage_share" "AVDProfileShare" {
  name               = "userprofiles"
  storage_account_id = azurerm_storage_account.FSLogixStorageAccount.id
  quota              = 100
  depends_on         = [azurerm_storage_account.FSLogixStorageAccount]
}