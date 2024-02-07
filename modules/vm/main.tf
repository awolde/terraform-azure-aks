variable "rg_name" {}

variable "location" {}

resource "random_id" "suffix" {
  byte_length = 2
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_id.suffix.hex}"
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "vmsubnet-${random_id.suffix.hex}"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.rg_name
  address_prefixes     = ["10.0.10.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic-${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "vmipconfig-${random_id.suffix.hex}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "pipip-${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "LinuxVm-${random_id.suffix.hex}"
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS1_v2"
  os_disk {
    name                 = "vmOsDisk${random_id.suffix.hex}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  admin_username                  = "azureadmin"
  admin_password                  = "Tomorrow@123"
  disable_password_authentication = "false"
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
