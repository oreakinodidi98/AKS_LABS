resource "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  address_space       = ["10.21.0.0/16"]
  location            = var.location
  resource_group_name = var.resourcegroup
}

resource "time_sleep" "wait_for_vnet" {
  depends_on      = [azurerm_virtual_network.example]
  create_duration = "30s"
}

resource "azurerm_subnet" "lustre" {
  name                 = "lustre"
  resource_group_name  = var.resourcegroup
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.21.1.0/24"]

  depends_on = [time_sleep.wait_for_vnet]
}

resource "azurerm_subnet" "aks_default_cpu" {
  name                 = "default"
  resource_group_name  = var.resourcegroup
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.21.2.0/24"]

  depends_on = [time_sleep.wait_for_vnet]
}

resource "azurerm_subnet" "aks_default_gpu" {
  name                 = "inference"
  resource_group_name  = var.resourcegroup
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.21.3.0/24"]

  depends_on = [time_sleep.wait_for_vnet]
}

resource "azurerm_managed_lustre_file_system" "example" {
  name                   = var.lustre_name
  resource_group_name    = var.resourcegroup
  location               = var.location
  sku_name               = var.lustre_sku_name
  subnet_id              = azurerm_subnet.lustre.id
  storage_capacity_in_tb = 4
  zones                  = ["2"]

  maintenance_window {
    day_of_week        = "Sunday"
    time_of_day_in_utc = "22:00"
  }
}