terraform {
  required_version = ">= 1.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.30.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = '$(sarg)'
    storage_account_name = "lgterraformsa"
    container_name       = "terraform"
    key                  = "adv.terraform.tfstate"
  }
}