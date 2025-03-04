# Azure Region Configuration
location = "westeurope"

# Azure Virtual Desktop (AVD) Host Pool Configuration
hostpool_name                     = "hostpool-avd-wstrp"
workspace_name                    = "workspace-avd-wstrp"
application_group_name_desktopapp = "application_group_name_desktopapp"
application_group_name_remoteapp  = "application_group_name_remoteapp"

# Virtual Machine Configuration
NumberOfSessionHosts = 1
vm_prefix            = "avd-h1"
vm_name              = "vm-avd-wstrp"
admin_username       = "threaten66" # Note: Consider using environment variables for sensitive values

# Networking Configuration
avd_vnet               = "vnet-avd-wstrp"
nic_name               = "nic-avd-wstrp"
bastion_name           = "bastion-avd-wstrp"
bastion_public_ip_name = "pip-bastion-avd-wstrp"

# Storage Configuration
storage_account_name = "fslogixprofiles1wstrp"