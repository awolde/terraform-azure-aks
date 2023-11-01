#output "acr_managed_identity_name" {
#  value = azurerm_user_assigned_identity.default.name
#}
#
#output "acr_name" {
#  value = azurerm_container_registry.default.name
#}
#
#output "webplan_name" {
#  value = azurerm_service_plan.default.name
#}

//github secrets
output "client_ids" {
  //loop through the list of client ids
  value = { for env in var.envs : env => azuread_service_principal.default[env].application_id }
}

//loop through the list of display names
output "service_principal_names" {
  value = {
    for env in var.envs : env => azuread_service_principal.default[env].display_name
  }
}

output "storage_account_names" {
  value = { for env in var.envs : env => azurerm_storage_account.tfstate[env].name }
}

output "storage_container_names" {
  value = { for env in var.envs : env => azurerm_storage_container.tfstate[env].name }
}

output "azuread_app_ids" {
  value = { for env in var.envs : env => azuread_application.default[env].object_id }
}