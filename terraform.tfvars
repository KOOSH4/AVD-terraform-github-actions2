# Resource Group Variables
resource_group_name = "rg-AVD2-pool-dewc"
location            = "westeurope"

# Network Variables
vnet_name = "vnet-avd2-wstrp"

# Virtual Machine Variables
NumberOfSessionHosts = 1
vm_prefix            = "avd-h1"
admin_username       = "threaten66" # Note: Consider using environment variables for sensitive values
avd_Location         = "westeurope"

# AVD Service Variables
hostpool_name                     = "hostpool-avd2-wstrp"
workspace_name                    = "workspace-avd2-wstrp"
application_group_name_desktopapp = "application_group_name_desktopapp"
application_group_name_remoteapp  = "application_group_name_remoteapp"

# Storage Variables
storage_account_name = "stavdprofiles001"