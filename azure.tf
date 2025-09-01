resource "azurerm_resource_group" "enexis_lab_rg" {
  name     = "enexis-lab-rg"
  location = "westeurope"
}

resource "azurerm_container_registry" "enexis_acr" {
  name                = "enexislabacr123"
  resource_group_name = azurerm_resource_group.enexis_lab_rg.name
  location            = azurerm_resource_group.enexis_lab_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_storage_account" "enexis_storage" {
  name                     = "enexislabstorage123"
  resource_group_name      = azurerm_resource_group.enexis_lab_rg.name
  location                 = azurerm_resource_group.enexis_lab_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_kubernetes_cluster" "enexis_aks" {
  name                = "enexis-lab-aks"
  location            = azurerm_resource_group.enexis_lab_rg.location
  resource_group_name = azurerm_resource_group.enexis_lab_rg.name
  dns_prefix          = "enexislab"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}