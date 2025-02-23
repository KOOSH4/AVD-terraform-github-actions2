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
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
}

resource "azurerm_storage_share" "AVDProfileShare" {
  name               = "avdprofiles"
  storage_account_id = azurerm_storage_account.FSLogixStorageAccount.id
  quota              = 100

}


resource "null_resource" "FSLogix" {
  count = var.NumberOfSessionHosts
  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${element(azurerm_windows_virtual_machine.main.*.name, count.index)} -g ${azurerm_resource_group.rg-AVD2.name} --scripts 'New-ItemProperty -Path HKLM:\\SOFTWARE\\FSLogix\\Profiles -Name VHDLocations -Value \\\\cloudninjafsl11072022.file.core.windows.net\\avdprofiles -PropertyType MultiString;New-ItemProperty -Path HKLM:\\SOFTWARE\\FSLogix\\Profiles -Name Enabled -Value 1 -PropertyType DWORD;New-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Lsa\\Kerberos\\Parameters -Name CloudKerberosTicketRetrievalEnabled -Value 1 -PropertyType DWORD;New-Item -Path HKLM:\\Software\\Policies\\Microsoft\\ -Name AzureADAccount;New-ItemProperty -Path HKLM:\\Software\\Policies\\Microsoft\\AzureADAccount  -Name LoadCredKeyFromProfile -Value 1 -PropertyType DWORD;Restart-Computer'"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [
    azurerm_virtual_machine_extension.AADLoginForWindows
  ]
}