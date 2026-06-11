output "jumpbox_password" {
  description = "Admin password for the Linux jumpbox VM"
  value       = module.VM.vm_admin_password
  sensitive   = true
}

output "aks_kubeconfig_path" {
  value       = module.aks.kube_config_path
  description = "Path to generated kubeconfig"
}

output "acr_login_server" {
  value = module.aks.acr_login_server
}

output "app_gateway_public_ip" {
  value = module.aks.pip_app_gateway
}

output "jumpbox_ssh_connection" {
  value = "ssh azureuser@${module.VM.vm_private_ip} (from within VNet)"
}

output "managed_identity_client_id" {
  value = module.aks.managed_identity_client_id
}