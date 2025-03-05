# -----------------------------
# Terraform Configuration
# -----------------------------
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

# -----------------------------
# Provider Configuration
# -----------------------------
provider "azurerm" {
  resource_provider_registrations = "none"
  features {

  }
}

# -----------------------------
# Resource Groups
# -----------------------------
resource "azurerm_resource_group" "rg_avd_service" {
  name     = "rg-AVD-Service-wstrp"
  location = var.location
  tags = {
    Purpose  = "AVD Service Components"
    Location = var.location
    Owner    = "Olad, Koosha"
  }
}

resource "azurerm_resource_group" "rg_session_hosts" {
  name     = "rg-AVD-SessionHosts-wstrp"
  location = var.location
  tags = {
    Purpose  = "AVD Session Hosts"
    Location = var.location
    Owner    = "Olad, Koosha"
  }
}

resource "azurerm_resource_group" "rg_network" {
  name     = "rg-AVD-Network-wstrp"
  location = var.location
  tags = {
    Purpose  = "AVD Networking"
    Location = var.location
    Owner    = "Olad, Koosha"
  }
}

resource "azurerm_resource_group" "rg_storage" {
  name     = "rg-AVD-Storage-wstrp"
  location = var.location
  tags = {
    Purpose  = "AVD Storage"
    Location = var.location
    Owner    = "Olad, Koosha"
  }
}

resource "azurerm_resource_group" "rg_monitoring" {
  name     = "rg-AVD-Monitoring-wstrp"
  location = var.location
  tags = {
    Purpose  = "AVD Monitoring"
    Location = var.location
    Owner    = "Olad, Koosha"
  }
}
