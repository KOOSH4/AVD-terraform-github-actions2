// Windows Virtual Machine and Extensions
resource "azurerm_windows_virtual_machine" "this" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = "Standard_D4s_v3"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [var.network_interface_id]

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
}

resource "azurerm_virtual_machine_extension" "aad_login" {
  name                       = "AADLogin"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_virtual_machine_extension" "avd_dsc" {
  name                       = "vm0-avd-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
  {
    "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
    "configurationFunction": "Configuration.ps1\\AddSessionHost",
    "properties": {
      "HostPoolId": "${var.host_pool_id}",
      "HostPoolName": "${var.host_pool_name}"
    }
  }
SETTINGS
  protected_settings         = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.registration_token}"
    }
  }
PROTECTED_SETTINGS
}

output "vm_id" {
  value = azurerm_windows_virtual_machine.this.id
}
