output "lustre_mgs_address" {
    description = "The MGS address of the managed Lustre file system"
    value       = azurerm_managed_lustre_file_system.example.mgs_address
}
output "lustre_fs_id" {
    description = "The ID of the managed Lustre file system"
    value       = azurerm_managed_lustre_file_system.example.id
}
output "lustre_name" {
    description = "The name of the managed Lustre file system"
    value       = azurerm_managed_lustre_file_system.example.name
}
output "lustre_sku_name" {
    description = "The SKU name of the managed Lustre file system"
    value       = azurerm_managed_lustre_file_system.example.sku_name
}
output "lustre_subnet_id" {
    description = "The ID of the subnet for the managed Lustre file system"
    value       = azurerm_subnet.lustre.id
}
output "lustre_subnet_name" {
    description = "The name of the subnet for the managed Lustre file system"
    value       = azurerm_subnet.lustre.name
}
output "lustre_subnet_address_prefix" {
    description = "The address prefix of the subnet for the managed Lustre file system"
    value       = azurerm_subnet.lustre.address_prefixes[0]
}
output "vnet_id" {
    description = "The ID of the virtual network"
    value       = azurerm_virtual_network.example.id
}
output "vnet_name" {
    description = "The name of the virtual network"
    value       = azurerm_virtual_network.example.name
}
output "vnet_address_space" {
    description = "The address space of the virtual network"
    value       = azurerm_virtual_network.example.address_space[0]
}
output "GPU_subnet_id" {
    description = "The ID of the GPU subnet"
    value       = azurerm_subnet.aks_default_gpu.id
}
output "GPU_subnet_name" {
    description = "The name of the GPU subnet"
    value       = azurerm_subnet.aks_default_gpu.name
}
output "GPU_subnet_address_prefix" {
    description = "The address prefix of the GPU subnet"
    value       = azurerm_subnet.aks_default_gpu.address_prefixes[0]
}
output "CPU_subnet_id" {
    description = "The ID of the CPU subnet"
    value       = azurerm_subnet.aks_default_cpu.id
}
output "CPU_subnet_name" {
    description = "The name of the CPU subnet"
    value       = azurerm_subnet.aks_default_cpu.name
}
output "CPU_subnet_address_prefix" {
    description = "The address prefix of the CPU subnet"
    value       = azurerm_subnet.aks_default_cpu.address_prefixes[0]
}