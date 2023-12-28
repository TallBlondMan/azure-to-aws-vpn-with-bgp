terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.85.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.19.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.10.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true

  features {}
}
provider "aws" {
  region = var.main_region
}

provider "time" {}