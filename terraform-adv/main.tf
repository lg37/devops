# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "myrg" {
  name     = var.RG_NAME
  location = "West Europe"
  tags = {
    env = "adv"
  }
}

module "hubvnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  vnet_name           = var.HUB_VNET_NAME
  resource_group_name = azurerm_resource_group.myrg.name
  use_for_each        = true
  vnet_location       = azurerm_resource_group.myrg.location
  address_space       = ["10.1.0.0/16"]
  subnet_names        = ["AzureFirewallSubnet", "subnet2"]
  subnet_prefixes     = ["10.1.1.0/26", "10.1.2.0/24"]
  nsg_ids = {
    subnet2 = azurerm_network_security_group.mysubnet-nsg.id
  }
  tags = {
    env = "adv"
  }
}

module "spoke1vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  vnet_name           = var.SPOKE1_VNET_NAME
  resource_group_name = azurerm_resource_group.myrg.name
  use_for_each        = true
  vnet_location       = azurerm_resource_group.myrg.location
  address_space       = ["10.2.0.0/16"]
  subnet_names        = ["subnet1", "subnet2"]
  subnet_prefixes     = ["10.2.1.0/24", "10.2.2.0/24"]
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
  vm_name   = "test-linux"
  vm_size   = "Standard_F2"
  rg        = azurerm_resource_group.myrg.name
  location  = "westeurope"
  subnet_id = module.spoke1vnet.vnet_subnets[0]
}

resource "azurerm_public_ip" "firewall-pip" {
  name                = "firewall-pip"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    env = "hub-firewall"
  }
}

data "azurerm_public_ip" "firewall-pip" {
  name                = azurerm_public_ip.firewall-pip.name
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_firewall_policy" "hubfirewall-policy" {
  name                = "hubfirewall-policy"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_firewall" "hub-firewall" {
  name                = "hubfirewall"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hubfirewall-policy.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.spoke1vnet.vnet_subnets[0]
    public_ip_address_id = azurerm_public_ip.firewall-pip.id
  }
}