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
  route_tables_ids = {
    subnet2 = azurerm_route_table.firewall-route-table.id
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
  use_for_each        = false
  vnet_location       = azurerm_resource_group.myrg.location
  address_space       = ["10.2.0.0/16"]
  subnet_names        = ["subnet1", "subnet2"]
  subnet_prefixes     = ["10.2.1.0/24", "10.2.2.0/24"]
  nsg_ids = {
    subnet1 = azurerm_network_security_group.mysubnet-nsg.id,
    subnet2 = azurerm_network_security_group.mysubnet-nsg.id
  }
  route_tables_ids = {
    subnet1 = azurerm_route_table.spoke1-route-table.id,
    subnet2 = azurerm_route_table.spoke1-route-table.id
  }
  tags = {
    env = "adv"
  }
}

module "spoke2vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  vnet_name           = var.SPOKE2_VNET_NAME
  resource_group_name = azurerm_resource_group.myrg.name
  use_for_each        = false
  vnet_location       = azurerm_resource_group.myrg.location
  address_space       = ["10.3.0.0/16"]
  subnet_names        = ["subnet1", "subnet2"]
  subnet_prefixes     = ["10.3.1.0/24", "10.3.2.0/24"]
  nsg_ids = {
    subnet1 = azurerm_network_security_group.mysubnet-nsg.id,
    subnet2 = azurerm_network_security_group.mysubnet-nsg.id
  }
  route_tables_ids = {
    subnet1 = azurerm_route_table.spoke2-route-table.id,
    subnet2 = azurerm_route_table.spoke2-route-table.id
  }
  tags = {
    env = "adv"
  }
}
# add vnet peerings

resource "azurerm_virtual_network_peering" "hub-to-spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.myrg.name
  virtual_network_name      = module.hubvnet.vnet_name
  remote_virtual_network_id = module.spoke1vnet.vnet_id
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.myrg.name
  virtual_network_name      = module.spoke1vnet.vnet_name
  remote_virtual_network_id = module.hubvnet.vnet_id
}

resource "azurerm_virtual_network_peering" "hub-to-spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.myrg.name
  virtual_network_name      = module.hubvnet.vnet_name
  remote_virtual_network_id = module.spoke2vnet.vnet_id
}

resource "azurerm_virtual_network_peering" "spoke2-to-hub" {
  name                      = "spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.myrg.name
  virtual_network_name      = module.spoke2vnet.vnet_name
  remote_virtual_network_id = module.hubvnet.vnet_id
}

# UDR for Spoke1

resource "azurerm_route_table" "spoke1-route-table" {
  name                          = "spoke1-route-table"
  location                      = azurerm_resource_group.myrg.location
  resource_group_name           = azurerm_resource_group.myrg.name
  disable_bgp_route_propagation = false
  tags = {
    env = "adv"
  }
}

resource "azurerm_route" "spoke1-default-route" {
  name                   = "spoke1-default-route"
  resource_group_name    = azurerm_resource_group.myrg.name
  route_table_name       = azurerm_route_table.spoke1-route-table.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub-firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "spoke1-spoke2-route" {
  name                   = "spoke1-spoke2-route"
  resource_group_name    = azurerm_resource_group.myrg.name
  route_table_name       = azurerm_route_table.spoke1-route-table.name
  address_prefix         = "10.3.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub-firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "spoke1-hub-route" {
  name                   = "spoke1-hub-route"
  resource_group_name    = azurerm_resource_group.myrg.name
  route_table_name       = azurerm_route_table.spoke1-route-table.name
  address_prefix         = "10.1.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub-firewall.ip_configuration[0].private_ip_address
}

# UDR for Spoke2

resource "azurerm_route_table" "spoke2-route-table" {
  name                          = "spoke2-route-table"
  location                      = azurerm_resource_group.myrg.location
  resource_group_name           = azurerm_resource_group.myrg.name
  disable_bgp_route_propagation = false
  tags = {
    env = "adv"
  }
}

resource "azurerm_route" "spoke2-default-route" {
  name                   = "spoke2-default-route"
  resource_group_name    = azurerm_resource_group.myrg.name
  route_table_name       = azurerm_route_table.spoke2-route-table.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub-firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "spoke2-spoke1-route" {
  name                   = "spoke2-spoke1-route"
  resource_group_name    = azurerm_resource_group.myrg.name
  route_table_name       = azurerm_route_table.spoke2-route-table.name
  address_prefix         = "10.2.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub-firewall.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "spoke2-hub-route" {
  name                   = "spoke2-hub-route"
  resource_group_name    = azurerm_resource_group.myrg.name
  route_table_name       = azurerm_route_table.spoke2-route-table.name
  address_prefix         = "10.1.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub-firewall.ip_configuration[0].private_ip_address
}

# create std NSG and NSG rule

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

# Create some VMs
module "add_vm_linux" {
  source    = "./modules/m-linuxvm"
  vm_name   = "test-linux"
  vm_size   = "Standard_F2"
  rg        = azurerm_resource_group.myrg.name
  location  = "westeurope"
  subnet_id = module.hubvnet.vnet_subnets[1]
}

module "add_vm_windows" {
  source    = "./modules/m-windowsvm"
  vm_name   = "test-windows"
  vm_size   = "Standard_F2"
  rg        = azurerm_resource_group.myrg.name
  location  = "westeurope"
  subnet_id = module.spoke1vnet.vnet_subnets[0]
}

module "add_vm_windows2" {
  source    = "./modules/m-windowsvm"
  vm_name   = "test-windows2"
  vm_size   = "Standard_F2"
  rg        = azurerm_resource_group.myrg.name
  location  = "westeurope"
  subnet_id = module.spoke2vnet.vnet_subnets[0]
}

# Create Firewall into HUB vnet
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
    subnet_id            = module.hubvnet.vnet_subnets[0]
    public_ip_address_id = azurerm_public_ip.firewall-pip.id
  }
}