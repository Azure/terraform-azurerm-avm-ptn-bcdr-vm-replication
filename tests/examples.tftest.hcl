provider "azurerm" {
  features {}
}

run "examples_default" {
  command = plan

  module {
    source = "./examples/default"
  }
}


