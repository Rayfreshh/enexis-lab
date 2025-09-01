terraform {
  required_version = ">= 1.3"

  backend "remote" {
    organization = "RAG"   # your Terraform Cloud org
    workspaces {
      name = "enexis-lab"  # your Terraform Cloud workspace
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.enexis_aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_key)

  insecure = true
}

provider "helm" {
  kubernetes {
    host               = azurerm_kubernetes_cluster.enexis_aks.kube_config[0].host
    client_certificate = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_certificate)
    client_key         = base64decode(azurerm_kubernetes_cluster.enexis_aks.kube_config[0].client_key)

    insecure = true
  }
}
