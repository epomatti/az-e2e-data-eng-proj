output "service_credential_secret_value" {
  value     = azuread_application_password.app.value
  sensitive = true
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

output "client_id" {
  value = azuread_application.app.client_id
}

output "service_principal_object_id" {
  value = azuread_service_principal.app.object_id
}
