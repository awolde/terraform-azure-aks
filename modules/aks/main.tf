//add vnet
resource "azurerm_virtual_network" "default" {
  name                = "vnet-${var.prefix}-${var.env}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.10.0.0/16"]
  tags = {
    Env          = "",
    Appname      = "tfo",
    AppOwner     = "Fname Lname",
    CreationDate = ""
  }
}

#//add subnet
resource "azurerm_subnet" "infra" {
  name                 = "subnet-${var.prefix}-${var.env}-001"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.10.0.0/23"]
}

//pls subnet
resource "azurerm_subnet" "pls" {
  name                                          = "subnet-${var.prefix}-${var.env}-002"
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.default.name
  address_prefixes                              = ["10.10.8.0/28"]
  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies_enabled     = false
}

//add test vm
resource "azurerm_public_ip" "vm" {
  name                = "vm-public-ip-${var.prefix}-${var.env}"
  sku                 = "Standard"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags = {
    Env          = "",
    Appname      = "tfo",
    AppOwner     = "Fname Lname",
    CreationDate = ""
  }
}

resource "azurerm_network_interface" "default" {
  name                = "nic-vm-${var.prefix}-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.infra.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
  tags = {
    Env          = "",
    Appname      = "tfo",
    AppOwner     = "Fname Lname",
    CreationDate = ""
  }
}
#
resource "azurerm_network_security_group" "default" {
  name                = "nsg-${var.prefix}-${var.env}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "73.8.114.254"
    destination_address_prefix = "*"
  }
  tags = {
    Env          = "",
    Appname      = "tfo",
    AppOwner     = "Fname Lname",
    CreationDate = ""
  }
}
#
resource "azurerm_network_interface_security_group_association" "default" {
  network_interface_id      = azurerm_network_interface.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

//add container registry
resource "azurerm_container_registry" "default" {
  name                  = "${var.prefix}${var.env}acr"
  resource_group_name   = var.resource_group_name
  location              = var.location
  sku                   = "Premium"
  admin_enabled         = false
  data_endpoint_enabled = true
  #  georeplication_locations = ["eastus2"]
}

/*
resource "azurerm_linux_virtual_machine" "default" {
  name                = "${var.prefix}-${var.env}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.default.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    #public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  tags = {
    Environment = var.env
  }
}
//end of vm
*/

//add user assigned identity to run aks cluster
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.prefix}-${var.env}-aks-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

//give the user assigned identity access to the vnet to create private link services
resource "azurerm_role_assignment" "ntk" {
  scope                = azurerm_subnet.infra.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "pls" {
  scope                = azurerm_virtual_network.default.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

//give the user assigned identity access to the container registry
resource "azurerm_role_assignment" "acr" {
  scope                = azurerm_container_registry.default.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

//add aks cluster
resource "azurerm_kubernetes_cluster" "default" {
  name                = "aks-${var.prefix}-${var.env}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-${var.env}-aks"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.prefix}-${var.env}-aks-nodes"
  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = var.vm_size
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    vnet_subnet_id      = azurerm_subnet.infra.id
    tags = {
      Env          = "",
      Appname      = "tfo",
      AppOwner     = "Fname Lname",
      CreationDate = ""
    }
  }
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks.id
    ]
  }
}

//add connected container registry
resource "azurerm_container_registry_scope_map" "default" {
  name                    = "${var.prefix}-${var.env}-scope-map"
  container_registry_name = azurerm_container_registry.default.name
  resource_group_name     = var.resource_group_name
  actions = [
    "repositories/app/content/read",
    "repositories/app/content/write",
    "repositories/app/content/delete",
    "repositories/app/metadata/read",
    "repositories/app/metadata/write",
    "gateway/${var.prefix}${var.env}connectedregistry/config/read",
    "gateway/${var.prefix}${var.env}connectedregistry/config/write",
    "gateway/${var.prefix}${var.env}connectedregistry/message/read",
    "gateway/${var.prefix}${var.env}connectedregistry/message/write",
  ]
}


resource "azurerm_role_assignment" "default" {
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.default.id
  skip_service_principal_aad_check = true
}

resource "azurerm_container_registry_token" "default" {
  name                    = "${var.prefix}-${var.env}-token"
  container_registry_name = azurerm_container_registry.default.name
  resource_group_name     = var.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.default.id
}

resource "azurerm_container_connected_registry" "default" {
  name                  = "${var.prefix}${var.env}connectedregistry"
  container_registry_id = azurerm_container_registry.default.id
  sync_token_id         = azurerm_container_registry_token.default.id
}
