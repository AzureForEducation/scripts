# Defining AzureRM as provider for Terraform
provider "azurerm" {
    version = "=1.28.0"
}

# Creating a new Resource Group
resource "azurerm_resource_group" "rg" {
    name = "your-cluster-name"
    location = "your-location" 
}

# Creating a new VNet
resource "azurerm_virtual_network" "network" {
  name                = "your-vnet-name"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space       = ["10.1.0.0/16"]
}

# Adding a Subnet into the existing VNet and linking to a existing Security Group
resource "azurerm_subnet" "subnet" {
  name                      = "your-subnet-name"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  address_prefix            = "10.1.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network.name}"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"
}

# Creating a new AKS cluster
resource "azurerm_kubernetes_cluster" "cluster" {
  name       = "your-aks-cluster-name"
  location   = "${azurerm_resource_group.rg.location}"
  dns_prefix = "${azurerm_kubernetes_cluster.name}"
  
  resource_group_name = "${azurerm_resource_group.rg.name}"
  kubernetes_version  = "1.14.6"

  agent_pool_profile {
    name           = "${azurerm_kubernetes_cluster.name}"
    count          = "1"
    vm_size        = "Standard_D2s_v3"
    os_type        = "Linux"
    vnet_subnet_id = "${azurerm_subnet.subnet.id}"
  }

  service_principal {
    client_id     = "your-service-principal-client-id"
    client_secret = "your-service-principal-client-secret"
  }

  network_profile {
    network_plugin = "azure"
  }
}

# Retrieving cluster's credentials
# Copy the content printed by the section below into a new file and save it.
# Export a environment variable loading the content of file: export KUBECONFIG="$PWD/<file-name>"
output "kube_config" {
  value = "${azurerm_kubernetes_cluster.cluster.kube_config_raw}"
}

# Adding a new Security Group to allow external communication
resource "azurerm_network_security_group" "sg" {
  name                = "your-security-group-name"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Adding Helm connector
provider "helm" {
  version = "0.9.1"
  kubernetes {
    host     = "${azurerm_kubernetes_cluster.cluster.kube_config.0.host}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)}"
    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)}"
  }
}

# Adding the ingress controller
resource "helm_release" "ingress" {
    name      = "ingress2"
    chart     = "stable/nginx-ingress"

    set {
        name  = "rbac.create"
        value = "true"
    }
}