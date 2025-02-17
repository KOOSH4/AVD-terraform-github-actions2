terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.19.0"
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

resource "azurerm_virtual_desktop_host_pool_registration_info" "registration" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "48h") # Extended token validity
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.rg-AVD2.name
  location              = azurerm_resource_group.rg-AVD2.location
  size                  = "Standard_D4s_v3"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-avd"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  provision_vm_agent = true

  # Remove the existing depends_on and replace with:
  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_virtual_desktop_host_pool.hostpool,
    azurerm_virtual_desktop_host_pool_registration_info.registration
  ]
}



resource "azurerm_network_interface" "vm_nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet_default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine_extension" "aad_login" {
  name                       = "AADLogin"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_windows_virtual_machine.vm]
}

resource "azurerm_virtual_machine_extension" "avd_dsc" {
  name                       = "vm0-avd-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
  {
    "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
    "configurationFunction": "Configuration.ps1\\AddSessionHost",
    "properties": {
      "HostPoolName": "${azurerm_virtual_desktop_host_pool.hostpool.name}"
    }
  }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.registration.token}"
    }
  }
PROTECTED_SETTINGS

  depends_on = [azurerm_virtual_desktop_host_pool.hostpool]
}




resource "azurerm_log_analytics_workspace" "avd_logs" {
  name                = "law-avd-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "avd_vm_diag" {
  name                       = "diag-avd-vm"
  target_resource_id         = azurerm_windows_virtual_machine.vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [azurerm_windows_virtual_machine.vm, azurerm_log_analytics_workspace.avd_logs]
}

resource "azurerm_monitor_diagnostic_setting" "avd_hostpool_diag" {
  name                       = "diag-avd-hostpool"
  target_resource_id         = azurerm_virtual_desktop_host_pool.hostpool.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  enabled_log { category = "Checkpoint" }
  enabled_log { category = "Error" }
  enabled_log { category = "Management" }
  enabled_log { category = "Connection" }
  enabled_log { category = "HostRegistration" }
  enabled_log { category = "AgentHealthStatus" }
  enabled_log { category = "NetworkData" }
  enabled_log { category = "ConnectionGraphicsData" }
  enabled_log { category = "SessionHostManagement" }
  enabled_log { category = "AutoscaleEvaluationPooled" }
  depends_on = [azurerm_windows_virtual_machine.vm, azurerm_log_analytics_workspace.avd_logs]

}

resource "azurerm_monitor_metric_alert" "avd_cpu_alert" {
  name                = "avd-vm-high-cpu"
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  scopes              = [azurerm_windows_virtual_machine.vm.id]
  description         = "Alert when average CPU usage on AVD VM exceeds 80% for 5 minutes."
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"

  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = var.location

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  depends_on = [azurerm_windows_virtual_machine.vm, azurerm_log_analytics_workspace.avd_logs]

}
