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

# -----------------------------
# Networking Configuration
# -----------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.avd_vnet
  location            = azurerm_resource_group.rg_network.location
  resource_group_name = azurerm_resource_group.rg_network.name
  address_space       = ["10.0.0.0/22"] #(~1000 addresses)22
}

resource "azurerm_subnet" "subnets" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg_network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/23"] #(~500 addresses) for AVD hosts23
  depends_on           = [azurerm_virtual_network.vnet]
}

resource "azurerm_network_interface" "main" {
  count               = var.NumberOfSessionHosts
  name                = "nic-${var.vm_prefix}-${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_session_hosts.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnets.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.subnets, azurerm_resource_group.rg_session_hosts]
}

# -----------------------------
# AVD Service Components
# -----------------------------
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                     = var.hostpool_name
  location                 = azurerm_resource_group.rg_avd_service.location
  resource_group_name      = azurerm_resource_group.rg_avd_service.name
  type                     = "Pooled"
  maximum_sessions_allowed = 6
  load_balancer_type       = "DepthFirst"
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  location            = azurerm_resource_group.rg_avd_service.location
  resource_group_name = azurerm_resource_group.rg_avd_service.name
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool]
}

resource "azurerm_virtual_desktop_application_group" "ag-desktopapp" {
  name                = var.application_group_name_desktopapp
  location            = azurerm_resource_group.rg_avd_service.location
  resource_group_name = azurerm_resource_group.rg_avd_service.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool]
}

resource "azurerm_virtual_desktop_application_group" "ag-remoteapp" {
  name                = var.application_group_name_remoteapp
  location            = azurerm_resource_group.rg_avd_service.location
  resource_group_name = azurerm_resource_group.rg_avd_service.name
  type                = "RemoteApp"
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool]
}

# -----------------------------
# Session Host VMs
# -----------------------------
resource "azurerm_windows_virtual_machine" "main" {
  count                 = var.NumberOfSessionHosts
  name                  = "vm-${var.vm_prefix}-${format("%02d", count.index + 1)}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg_session_hosts.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  size                  = "Standard_D2s_v3"
  license_type          = "Windows_Client"
  admin_username        = var.admin_username
  admin_password        = var.admin_password

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "office-365"
    sku       = "win11-21h2-avd-m365"
    version   = "latest"
  }

  os_disk {
    name                 = "vm-${var.vm_prefix}-${format("%02d", count.index + 1)}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  depends_on = [
    azurerm_virtual_desktop_host_pool.hostpool,
    azurerm_network_interface.main,
    azurerm_virtual_desktop_host_pool_registration_info.registrationkey
  ]
}

# -----------------------------
# Storage Configuration
# -----------------------------
resource "azurerm_storage_account" "FSLogixStorageAccount" {
  name                     = lower(replace(var.storage_account_name, "-", ""))
  resource_group_name      = azurerm_resource_group.rg_storage.name
  location                 = azurerm_resource_group.rg_storage.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  large_file_share_enabled = true
  depends_on = [
  azurerm_resource_group.rg_storage, ]
}

resource "azurerm_storage_share" "AVDProfileShare" {
  name               = "profiles"
  storage_account_id = azurerm_storage_account.FSLogixStorageAccount.id
  quota              = 100
  depends_on         = [azurerm_storage_account.FSLogixStorageAccount]
}

# -----------------------------
# Monitoring Configuration
# -----------------------------
resource "azurerm_log_analytics_workspace" "avd_logs" {
  name                = "law-avd-logs"
  location            = azurerm_resource_group.rg_monitoring.location
  resource_group_name = azurerm_resource_group.rg_monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "avd_vm_diag" {
  count                      = length(azurerm_windows_virtual_machine.main)
  name                       = "diag-avd-vm-${count.index + 1}"
  target_resource_id         = azurerm_windows_virtual_machine.main[count.index].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
  depends_on = [azurerm_windows_virtual_machine.main, azurerm_log_analytics_workspace.avd_logs]
}

resource "azurerm_monitor_metric_alert" "avd_cpu_alert" {
  // Alert name and associated resource group
  name                = "avd-vm-high-cpu"
  resource_group_name = azurerm_resource_group.rg_monitoring.name

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

# -----------------------------
# VM Extensions
# -----------------------------
resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  count                      = var.NumberOfSessionHosts
  name                       = "AADLoginForWindows"
  virtual_machine_id         = element(azurerm_windows_virtual_machine.main.*.id, count.index)
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_windows_virtual_machine.main]

}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationkey" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "180m")
  depends_on      = [azurerm_virtual_desktop_host_pool.hostpool]
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
            "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.registrationkey.token}" 
        }
    }
SETTINGS

  depends_on = [azurerm_windows_virtual_machine.main]
}


resource "azurerm_virtual_machine_extension" "FSLogixConfig" {
  count                = var.NumberOfSessionHosts
  name                 = "FSLogixConfig-${count.index}"
  virtual_machine_id   = element(azurerm_windows_virtual_machine.main.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = jsonencode({
    "commandToExecute" : "powershell -ExecutionPolicy Unrestricted -File InstallFSLogixApps.ps1 -storageAccountName '${azurerm_storage_account.FSLogixStorageAccount.name}' -fileShareName '${azurerm_storage_share.AVDProfileShare.name}' -secret '${azurerm_storage_account.FSLogixStorageAccount.primary_access_key}'",
    "fileUris" : ["https://raw.githubusercontent.com/KOOSH4/FSLogix-_Powershell_silent_install/refs/heads/main/InstallFSLogixApps.ps1"]
  })

  depends_on = [
    azurerm_virtual_machine_extension.AADLoginForWindows,
    azurerm_windows_virtual_machine.main,
    azurerm_storage_account.FSLogixStorageAccount,
    azurerm_storage_share.AVDProfileShare,
    azurerm_virtual_machine_extension.dsc
  ]
}
# -----------------------------
# Workspace-Application Group Associations
# -----------------------------
resource "azurerm_virtual_desktop_workspace_application_group_association" "desktopapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.ag-desktopapp.id
  depends_on           = [azurerm_virtual_desktop_workspace.workspace, azurerm_virtual_desktop_application_group.ag-desktopapp]
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "remoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.ag-remoteapp.id
  depends_on           = [azurerm_virtual_desktop_workspace.workspace, azurerm_virtual_desktop_application_group.ag-remoteapp]
}
