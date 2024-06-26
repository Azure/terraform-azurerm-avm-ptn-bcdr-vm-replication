terraform {
  required_version = ">=1.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.11.0, <4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
provider "random" {
  # Optionally you can specify a version
  # version = "~> 3.0"
}

provider "azurerm" {
  alias = "target"
  subscription_id = "3910f612-759e-4488-97d5-1262a017e92e"
  features {}
  skip_provider_registration = true
}
