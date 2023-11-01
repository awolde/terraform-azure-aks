variable "prefix" {
  default = "orgname"
}
variable "github_org" {
  default = "github-org-name"
}

variable "azuread_app_ids" {
  type = map(string)
}

variable "repos" {
  type = list(string)
}

//create local variable by flattening the map
locals {
  pairs = flatten([
    for env, id in var.azuread_app_ids : flatten([
      for repo in var.repos :
      {
        repo   = repo
        app_id = id
        env    = env
      }
    ])
  ])
}

//add random string
resource "random_string" "random" {
  length  = 4
  special = false
}

resource "azuread_application_federated_identity_credential" "pr" {
  for_each              = { for idx, v in local.pairs : "${v.repo}${v.app_id}" => v }
  application_object_id = var.azuread_app_ids[each.value.env]
  display_name          = "${var.prefix}-${each.value.env}-gh-actions-on-pr-${each.value.repo}"
  description           = "Trigger via pr for ${each.value.repo} in ${each.value.env}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_org}/${each.value.repo}:environment:${each.value.env}"
}


resource "azuread_application_federated_identity_credential" "merge" {
  for_each              = { for idx, v in local.pairs : "${v.repo}${v.app_id}" => v }
  application_object_id = var.azuread_app_ids[each.value.env]
  display_name          = "${var.prefix}-gh-actions-on-merge-${each.value.repo}"
  description           = "Trigger via merge for ${each.value.repo} to main"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_org}/${each.value.repo}:ref:refs/heads/main"
}