terraform {
  required_version = ">=1.4.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.58.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.39.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-001"
    storage_account_name = "storgnametfstateqalgpsc4ay"
    container_name       = "tfstate-qa-container"
    key                  = "qa-aks.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

module "orgname_aks_qa" {
  source              = "../modules/aks"
  env                 = "qa"
  prefix              = "orgname"
  resource_group_name = "rg-orgname-qa-001"
}
