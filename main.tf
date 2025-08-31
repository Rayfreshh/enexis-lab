# Configure Azure provider
provider "azurerm" {
  features {}
  subscription_id = "5e264152-f690-4952-99e0-c243636d5a21"
}

# Kubernetes + Helm providers
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.enexis_aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.enexis_aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].cluster_ca_certificate)
  }
}

# Resource group
resource "azurerm_resource_group" "enexis_lab_rg" {
  name     = "enexis-lab-rg"
  location = "westeurope"
}

# Storage Account
resource "azurerm_storage_account" "enexis_storage" {
  name                     = "enexislabstorage123"
  resource_group_name      = azurerm_resource_group.enexis_lab_rg.name
  location                 = azurerm_resource_group.enexis_lab_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container Registry
resource "azurerm_container_registry" "enexis_acr" {
  name                = "enexislabacr123"
  resource_group_name = azurerm_resource_group.enexis_lab_rg.name
  location            = azurerm_resource_group.enexis_lab_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# AKS Cluster
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

# Reuse existing static public IP for ingress
data "azurerm_public_ip" "existing_ingress_ip" {
  name                = "b1e2b6ac-adc7-4f7e-8304-35db12ea75d8"   # your Azure IP resource name
  resource_group_name = "MC_enexis-lab-rg_enexis-lab-aks_westeurope"
}

# Install ingress-nginx using Helm
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.loadBalancerIP"
    value = data.azurerm_public_ip.existing_ingress_ip.ip_address
  }
}

# Ingress definition
resource "kubernetes_ingress_v1" "enexis_ingress" {
  metadata {
    name      = "enexis-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = "enexis-app.westeurope.cloudapp.azure.com"
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "enexis-microservice-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
