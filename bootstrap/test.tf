terraform {
  required_version = ">=1.4.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.7.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.39.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "orgname-dev-tf"
    storage_account_name = "tfstate22296"
    container_name       = "bootstrap"
    key                  = "bootstrap.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

module "orgnamedev" {
  source      = "../"
  location    = "eastus"
  admin_email = "c4692bfd-7566-zzzz-yyyyy-xxxxxxx"
  prefix      = "orgname"
  envs        = ["dev", "qa"]
  mandatory_tags = {
    Env          = "",
    Appname      = "tfo",
    AppOwner     = "Fname Lname",
    CreationDate = ""
  }
}

output "azure_client_id" {
  value = module.orgnamedev.client_ids
}

output "azure_principal_names" {
  value = module.orgnamedev.service_principal_names
}

output "storage_container_names" {
  value = module.orgnamedev.storage_container_names
}

output "storage_account_names" {
  value = module.orgnamedev.storage_account_names
}

module "add_repos" {
  github_org      = "gh-orgname"
  source          = "../modules/github-azure-federation"
  azuread_app_ids = module.orgnamedev.azuread_app_ids
  repos = [
    "deploy-terraform-azure-orgname-aks",
    "deploy-terraform-azure-github-actions",
    "deploy-terraform-azure-another-repo"
  ]
}