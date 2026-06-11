output "vm_admin_password" {
  description = "Generated admin password for the Linux VM"
  value       = random_password.vm_admin_password.result
  sensitive   = true
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.vm-linux-jumpbox.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm-linux-jumpbox.name
}

output "vm_private_ip" {
  value       = azurerm_network_interface.nic-vm-linux.private_ip_address
  description = "Private IP of jumpbox for SSH access within VNet"
}

output "nic_id" {
  value = azurerm_network_interface.nic-vm-linux.id
}