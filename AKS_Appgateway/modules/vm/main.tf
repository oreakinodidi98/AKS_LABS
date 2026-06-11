
resource "random_password" "vm_admin_password" {
  length           = 20
  special          = true
  override_special = "!@#$%"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_network_interface" "nic-vm-linux" {
  name                = var.nic_name
  resource_group_name = var.resourcegroup
  location            = var.location

  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = null # azurerm_public_ip.pip-vm-linux.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-linux-jumpbox" {
  name                            = var.vm_name
  resource_group_name             = var.resourcegroup
  location                        = var.location
  size                            = "Standard_D2ads_v6"
  disable_password_authentication = false
  admin_username                  = "azureuser"
  admin_password                  = random_password.vm_admin_password.result
  network_interface_ids           = [azurerm_network_interface.nic-vm-linux.id]
  priority                        = "Spot"
  eviction_policy                 = "Delete"
  disk_controller_type            = "NVMe" # "SCSI" # "IDE" # "SCSI" is the default value. "NVMe" is only supported for Ephemeral OS Disk.

  os_disk {
    name                 = "os-disk-vm-linux"
    caching              = "ReadOnly"        # "ReadWrite" # None, ReadOnly and ReadWrite.
    storage_account_type = "StandardSSD_LRS" # "Standard_LRS"
    disk_size_gb         = 64

    diff_disk_settings {
      option    = "Local"    # Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is Local.
      placement = "NvmeDisk" # "ResourceDisk" # "CacheDisk" # Specifies the Ephemeral Disk Placement for the OS Disk. NvmeDisk can only be used for v6 VMs
    }
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-2404" # "0001-com-ubuntu-server-jammy"
    sku       = "minimal"      # "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

