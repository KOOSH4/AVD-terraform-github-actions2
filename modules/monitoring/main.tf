resource "azurerm_log_analytics_workspace" "avd_logs" {
  name                = "law-avd-logs"
  location            = var.location
  resource_group_name = var.resource_group_name  // Using variable instead of direct reference
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "avd_vm_diag" {
  name                       = "diag-avd-vm"
  target_resource_id         = var.vm_id  // Using variable instead of direct reference
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd_logs.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "avd_hostpool_diag" {
  name                       = "diag-avd-hostpool"
  target_resource_id         = var.hostpool_id  // Using variable instead of direct reference
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
}

resource "azurerm_monitor_metric_alert" "avd_cpu_alert" {
  name                = "avd-vm-high-cpu"
  resource_group_name = var.resource_group_name  // Using variable instead of direct reference
  scopes              = [var.vm_id]  // Using variable instead of direct reference
  description         = "Alert when average CPU usage on AVD VM exceeds 80% for 5 minutes."
  severity            = 2
  window_size         = "PT5M"
  frequency          = "PT1M"

  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = var.location

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
}