data "azurerm_resource_group" "example" {
  name = "1-212a88f9-playground-sandbox"
}

output "id" {
  value = data.azurerm_resource_group.example.id
}