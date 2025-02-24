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

resource "azurerm_subnet" "subnets" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg-AVD2.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}


resource "azurerm_network_interface" "main" {
  count               = var.NumberOfSessionHosts
  name                = "nic-${var.vm_prefix}-${format("%02d", count.index + 1)}"
  location            = var.avd_Location
  resource_group_name = azurerm_resource_group.rg-AVD2.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnets.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  count                      = var.NumberOfSessionHosts
  name                       = "AADLoginForWindows"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.main.*.id, count.index)
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}


resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                     = var.hostpool_name
  location                 = azurerm_resource_group.rg-AVD2.location
  resource_group_name      = azurerm_resource_group.rg-AVD2.name
  type                     = "Pooled"
  maximum_sessions_allowed = 6
  load_balancer_type       = "DepthFirst"
}

resource "azurerm_virtual_desktop_application_group" "ag-desktopapp" {
  name                = var.application_group_name_desktopapp
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
}

resource "azurerm_virtual_desktop_application_group" "ag-remoteapp" {
  name                = var.application_group_name_remoteapp
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name

  type         = "RemoteApp"
  host_pool_id = azurerm_virtual_desktop_host_pool.hostpool.id
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  location            = azurerm_resource_group.rg-AVD2.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool]
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "desktopapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.ag-desktopapp.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "remoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.ag-remoteapp.id
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationkey" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "180m")
  depends_on      = [azurerm_virtual_desktop_host_pool.hostpool]
}



## Create the session hosts (VMs) for the host pool
resource "azurerm_windows_virtual_machine" "main" {
  count                 = var.NumberOfSessionHosts
  name                  = "vm-${var.vm_prefix}-${format("%02d", count.index + 1)}"
  location              = var.avd_Location
  resource_group_name   = azurerm_resource_group.rg-AVD2.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  size                  = "Standard_D2s_v3"
  license_type          = "Windows_Client"
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  additional_capabilities {
  }
  identity {
    type = "SystemAssigned"
  }
  source_image_reference {
    offer     = "office-365"
    publisher = "microsoftwindowsdesktop"
    sku       = "win11-21h2-avd-m365"
    version   = "latest"
  }
  os_disk {
    name                 = "vm-${var.vm_prefix}-${format("%02d", count.index + 1)}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  depends_on = [
    azurerm_virtual_desktop_host_pool.hostpool, azurerm_network_interface.main, azurerm_virtual_desktop_host_pool_registration_info.registrationkey
  ]
}

variable "avd_agent_location" {
  type    = string
  default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_06-15-2022.zip"
}
resource "azurerm_virtual_machine_extension" "dsc" {
  count                      = var.NumberOfSessionHosts
  name                       = "AddToAVD"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.main.*.id, count.index)
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
            {
                "modulesUrl": "${var.avd_agent_location}",
                "configurationFunction": "Configuration.ps1\\AddSessionHost",            
                "properties": {
                    "hostPoolName": "${azurerm_virtual_desktop_host_pool.hostpool.name}",
                    "aadJoin": true,
                    "UseAgentDownloadEndpoint": true,
                    "aadJoinPreview": false,
                    "mdmId": "",
                    "sessionHostConfigurationLastUpdateTime": "",
                    "registrationInfoToken" : "${azurerm_virtual_desktop_host_pool_registration_info.registrationkey.token}" 
                }
            }
            SETTINGS  

  depends_on = [
    azurerm_windows_virtual_machine.main
  ]
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


resource "azurerm_virtual_machine_extension" "FSLogixConfig" {
  count                = var.NumberOfSessionHosts
  name                 = "FSLogixConfig-${count.index}"
  virtual_machine_id   = element(azurerm_windows_virtual_machine.main.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    "fileUris" : ["https://raw.githubusercontent.com/acapodil/Azure-Virtual-Desktop/main/Scripts/customScriptTerraform.ps1"],
    "commandToExecute" : "powershell -ExecutionPolicy Unrestricted -File customScriptTerraform.ps1 ${azurerm_storage_account.FSLogixStorageAccount.name} ${azurerm_storage_share.AVDProfileShare.name}"
  })


  depends_on = [
    azurerm_virtual_machine_extension.AADLoginForWindows, azurerm_windows_virtual_machine.main, azurerm_storage_share.AVDProfileShare, azurerm_storage_account.FSLogixStorageAccount, azurerm_virtual_machine_extension.dsc
  ]
}



resource "azurerm_log_analytics_workspace" "avd_logs" {
  name                = "law-avd-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-AVD2.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

// This resource now uses count to iterate over all virtual machines defined
// in azurerm_windows_virtual_machine.main, creating a diagnostic setting for each.
// Each setting sends "AllMetrics" data to the specified Log Analytics Workspace.
resource "azurerm_monitor_diagnostic_setting" "avd_vm_diag" {
  count = length(azurerm_windows_virtual_machine.main)

  // Unique name for each diagnostic setting resource
  name = "diag-avd-vm-${count.index + 1}"

  // Target VM for which diagnostics are captured
  target_resource_id = azurerm_windows_virtual_machine.main[count.index].id

  // Reference to the Log Analytics Workspace for sending diagnostic data
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  // Configure metrics collection for all available metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  // Ensure the diagnostic settings are applied after the VMs and the workspace are created
  depends_on = [
    azurerm_windows_virtual_machine.main,
    azurerm_log_analytics_workspace.avd_logs
  ]
}
# Storage Account Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "avd_storage_diag" {
  name                       = "diag-avd-storage"
  target_resource_id         = azurerm_storage_account.FSLogixStorageAccount.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  enabled_log {
    category_group = "audit" # Changed from individual category to category_group
  }

  enabled_log {
    category_group = "allLogs" # Added allLogs category group
  }

  metric {
    category = "Transaction"
    enabled  = true
  }

  depends_on = [azurerm_storage_account.FSLogixStorageAccount, azurerm_log_analytics_workspace.avd_logs]
}

# Host Pool Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "avd_hostpool_diag" {
  name                       = "diag-avd-hostpool"
  target_resource_id         = azurerm_virtual_desktop_host_pool.hostpool.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  enabled_log {
    category_group = "audit" # Changed from individual category to category_group
  }

  # Removed the metrics block since it's not supported for this resource type

  depends_on = [azurerm_windows_virtual_machine.main, azurerm_log_analytics_workspace.avd_logs]
}
resource "azurerm_monitor_metric_alert" "avd_cpu_alert" {
  // Alert name and associated resource group
  name                = "avd-vm-high-cpu"
  resource_group_name = azurerm_resource_group.rg-AVD2.name

  // Apply alert to all VMs by referencing the list of VM ids using the splat operator
  scopes = azurerm_windows_virtual_machine.main[*].id

  // Description explains when the alert is triggered
  description = "Alert when average CPU usage on all AVD VMs exceeds 80% for 5 minutes."

  // Severity, window size, and frequency settings for the alert
  severity    = 2
  window_size = "PT5M"
  frequency   = "PT1M"

  // Target resource configuration for alert evaluation
  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = var.location

  // Criteria block defines the CPU metric threshold and aggregation method
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  // Ensure dependencies are created before the metric alert
  depends_on = [
    azurerm_windows_virtual_machine.main,
    azurerm_log_analytics_workspace.avd_logs
  ]
}