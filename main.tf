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

// Module calls replacing resource definitions
module "resource_group" {
  source              = "./modules/resource_group"
}

module "network" {
  source                 = "./modules/network"
  resource_group_name    = module.resource_group.resource_group_name
  location               = var.location
  vnet_name              = var.vnet_name
  bastion_public_ip_name = var.bastion_public_ip_name
}

module "virtual_desktop" {
  source                 = "./modules/virtual_desktop"
}

module "virtual_machine" {
  source               = "./modules/virtual_machine"
  resource_group_name  = module.resource_group.resource_group_name
  location             = var.location
  vm_name              = var.vm_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  nic_name             = var.nic_name
  network_interface_id = module.network.vm_nic_id
  host_pool_id         = module.virtual_desktop.hostpool_id
  registration_token   = module.virtual_desktop.registration_token
}

module "monitoring" {
  source = "./modules/monitoring"
}
