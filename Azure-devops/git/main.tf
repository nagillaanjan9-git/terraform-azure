#https://chatgpt.com/c/693550be-96b8-8321-a9f6-a6d58153bf7b

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-basic"
  location = "South India"
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acraksbasic123"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {

for_each = var.clusters


#name                = "aks-basic-cluster"
#location            = azurerm_resource_group.rg.location
#resource_group_name = azurerm_resource_group.rg.name
#dns_prefix          = "aksbasic"

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${each.value.name}-dns"

  default_node_pool {
    name       = "nodepool1"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
    #   os_type    = "Linux"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    env = "dev"
  }
}

/*
# Allow AKS to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Output kubeconfig gave sensitive = true Terraform hides sensitive values to prevent secrets leaking in logs or terminals
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  filename = "${path.module}/kubeconfig"
}

output "kube_admin_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}
*/

resource "azurerm_role_assignment" "acr_pull" {
  for_each = azurerm_kubernetes_cluster.aks

  principal_id         = each.value.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

resource "local_file" "kubeconfig" {
  for_each = azurerm_kubernetes_cluster.aks

  content  = each.value.kube_admin_config_raw
  filename = "${path.module}/${each.key}-kubeconfig"
}

output "kube_admin_config" {
  value = {
    for k, v in azurerm_kubernetes_cluster.aks :
    k => v.kube_admin_config_raw
  }
  sensitive = true
}
