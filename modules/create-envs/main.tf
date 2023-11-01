//add azure resource group for blob storage
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate-001"
  location = var.location
  tags = merge(var.mandatory_tags,
    {
      Env = "nonprod"
    }
  )
}

//create random string for storage account
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

//add azure blob storage for each env
resource "azurerm_storage_account" "tfstate" {
  for_each                 = toset(var.envs)
  name                     = "storgnametfstate${each.key}${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"
  access_tier              = "Cool"
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
  tags = merge(var.mandatory_tags,
    {
      Env = each.key
    }
  )
}

//add azure blob container for each env
resource "azurerm_storage_container" "tfstate" {
  for_each              = toset(var.envs)
  name                  = "tfstate-${each.key}-container"
  storage_account_name  = azurerm_storage_account.tfstate[each.key].name
  container_access_type = "private"
}

#data "azuread_client_config" "current" {}

#
#data "azuread_user" "default" {
#  user_principal_name = var.admin_email
#}
//create resource group for each env
resource "azurerm_resource_group" "default" {
  for_each = toset(var.envs)
  name     = "rg-${var.prefix}-${each.key}-001"
  location = var.location
  tags = merge(var.mandatory_tags,
    {
      Env = each.key
    }
  )
}
//add azure active directory application for github
resource "azuread_application" "default" {
  for_each     = toset(var.envs)
  display_name = "${var.prefix}-${each.key}-github-actions-ad"
  owners       = [var.admin_email]
}

resource "azuread_service_principal" "default" {
  for_each                     = toset(var.envs)
  application_id               = azuread_application.default[each.key].application_id
  app_role_assignment_required = false
  owners                       = [var.admin_email]
}

//add perm for github actions to deploy resources in azure
resource "azurerm_role_assignment" "contributor" {
  for_each             = toset(var.envs)
  scope                = azurerm_resource_group.default[each.key].id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.default[each.key].object_id
}

//assign service principal to container blob data contributor
resource "azurerm_role_assignment" "blob_contributor" {
  for_each             = toset(var.envs)
  scope                = azurerm_storage_account.tfstate[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.default[each.key].object_id
}