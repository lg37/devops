# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "myrg" {
  name     = var.rg_name
  location = "West Europe"
  tags = {
    env = "adv"
  }
}

module "myvnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  vnet_name           = var.vnet_name
  resource_group_name = azurerm_resource_group.myrg.name
  use_for_each        = true
  vnet_location       = azurerm_resource_group.myrg.location
  address_space       = ["10.1.0.0/16"]
  subnet_names        = ["subnet1", "subnet2"]
  subnet_prefixes     = ["10.1.1.0/24", "10.1.2.0/24"]
  nsg_ids = {
    subnet1 = azurerm_network_security_group.mysubnet-nsg.id,
    subnet2 = azurerm_network_security_group.mysubnet-nsg.id
  }
  tags = {
    env = "adv"
  }
}

resource "azurerm_network_security_group" "mysubnet-nsg" {
  name                = "subnets-nsg"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  tags = {
    env = "adv"
  }
}

resource "azurerm_network_security_rule" "subnet-nsg-rule" {
  name                        = "allow-all-in"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.myrg.name
  network_security_group_name = azurerm_network_security_group.mysubnet-nsg.name
}

module "add_vm" {
  source    = "./modules/m-linuxvm"
  vm_name   = "mon-linux"
  vm_size   = "Standard_F2"
  rg        = azurerm_resource_group.myrg.name
  location  = "westeurope"
  subnet_id = module.myvnet.vnet_subnets[0]
}