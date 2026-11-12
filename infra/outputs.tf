output "api_url" {
  description = "Public API URL."
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "frontend_url" {
  description = "Static website URL."
  value       = azurerm_storage_account.frontend.primary_web_endpoint
}

output "redis_hostname" {
  description = "Azure Cache for Redis hostname used by the API."
  value       = azurerm_redis_cache.app.hostname
}

output "resource_group_name" {
  description = "Resource group containing the app."
  value       = azurerm_resource_group.app.name
}

output "storage_account_name" {
  description = "Storage account used by the frontend upload script."
  value       = azurerm_storage_account.frontend.name
}
