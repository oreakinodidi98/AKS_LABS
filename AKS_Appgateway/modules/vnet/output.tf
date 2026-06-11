#output vnet id
output "vnet_spoke_id" {
    description = "ID of the vnet-spoke"
    value = azurerm_virtual_network.vnet-spoke.id
}
#output AKS subnet id
output "aks_subnet_id" {
    description = "ID of the AKS subnet"
    value = azurerm_subnet.snet-aks.id
}
#output App gateway subnet id
output "app_gateway_subnet_id" {
    description = "ID of the App Gateway subnet"
    value = azurerm_subnet.snet-appgateway.id
}
#output VM subnet id
output "vm_subnet_id" {
    description = "ID of the VM subnet"
    value = azurerm_subnet.snet-vm.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet-spoke.name
}

output "aks_subnet_address_prefix" {
  value = azurerm_subnet.snet-aks.address_prefixes
}

output "appgateway_subnet_address_prefix" {
  value = azurerm_subnet.snet-appgateway.address_prefixes
}